local config = require("databricks.config")
local cluster = require("databricks.cluster")
local ui = require("databricks.ui")

local M = {}

--- Last run ID
M._last_run_id = nil

--- Helper to execute CLI commands asynchronously
--- @param args string[] Command arguments ("databricks" is prepended automatically)
--- @param callback fun(stdout: string, exit_code: number)
local function exec_cli(args, callback)
  local cfg = config.get()
  local cmd = { "databricks" }

  -- Append profile option
  table.insert(cmd, "--profile")
  table.insert(cmd, cfg.profile)

  for _, a in ipairs(args) do
    table.insert(cmd, a)
  end

  local stdout_chunks = {}
  local stderr_chunks = {}

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(stdout_chunks, line)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(stderr_chunks, line)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        local stdout = table.concat(stdout_chunks, "\n")
        local stderr = table.concat(stderr_chunks, "\n")

        if exit_code ~= 0 then
          -- Mask sensitive information
          stderr = stderr:gsub("[Tt]oken%s*[=:]%s*%S+", "token=***")
          stderr = stderr:gsub("[Hh]ost%s*[=:]%s*%S+", "host=***")
          ui.show_error("CLI failed (exit " .. exit_code .. "): " .. stderr)
        end

        callback(stdout, exit_code)
      end)
    end,
  })
end

--- Upload file to DBFS
--- @param local_path string
--- @param callback fun(dbfs_path: string|nil)
local function upload_file(local_path, callback)
  local cfg = config.get()
  local filename = vim.fn.fnamemodify(local_path, ":t")
  local dbfs_path = cfg.upload_path .. "/" .. filename

  ui.set_status("Uploading " .. filename .. " to DBFS...")

  exec_cli({
    "fs", "cp",
    local_path,
    dbfs_path,
    "--overwrite",
  }, function(_, exit_code)
    if exit_code == 0 then
      ui.set_status("Upload complete: " .. dbfs_path)
      callback(dbfs_path)
    else
      callback(nil)
    end
  end)
end

--- Submit a one-time job run
--- @param dbfs_path string
--- @param cluster_id string
--- @param callback fun(run_id: string|nil)
local function submit_job(dbfs_path, cluster_id, callback)
  ui.set_status("Submitting job...")

  -- Build JSON payload safely (using vim.json.encode instead of string concatenation)
  local payload = vim.json.encode({
    run_name = "databricks-nvim-run",
    tasks = {
      {
        task_key = "databricks_nvim_task",
        existing_cluster_id = cluster_id,
        spark_python_task = {
          python_file = dbfs_path,
        },
      },
    },
  })

  -- Pass JSON via temp file to prevent shell injection
  local tmpfile = vim.fn.tempname() .. ".json"
  local f = io.open(tmpfile, "w")
  if not f then
    ui.show_error("Failed to create temp file")
    callback(nil)
    return
  end
  f:write(payload)
  f:close()

  exec_cli({
    "jobs", "submit",
    "--json", "@" .. tmpfile,
  }, function(stdout, exit_code)
    -- Always remove temp file
    os.remove(tmpfile)

    if exit_code ~= 0 then
      callback(nil)
      return
    end

    local ok, parsed = pcall(vim.json.decode, stdout)
    if not ok or type(parsed) ~= "table" then
      ui.show_error("Failed to parse job submit response")
      callback(nil)
      return
    end

    local run_id = parsed.run_id
    if not run_id then
      ui.show_error("No run_id in submit response")
      callback(nil)
      return
    end

    M._last_run_id = tostring(run_id)
    ui.set_status("Job submitted: run_id=" .. M._last_run_id)
    callback(M._last_run_id)
  end)
end

--- Poll run status until completion
--- @param run_id string
--- @param callback fun(success: boolean)
local function poll_run(run_id, callback)
  local cfg = config.get()

  local function check()
    exec_cli({
      "runs", "get",
      "--run-id", run_id,
    }, function(stdout, exit_code)
      if exit_code ~= 0 then
        callback(false)
        return
      end

      local ok, parsed = pcall(vim.json.decode, stdout)
      if not ok or type(parsed) ~= "table" then
        ui.show_error("Failed to parse run status")
        callback(false)
        return
      end

      local state = parsed.state
      if not state then
        ui.show_error("No state in run response")
        callback(false)
        return
      end

      local life_cycle = state.life_cycle_state
      local result_state = state.result_state

      if life_cycle == "TERMINATED" then
        if result_state == "SUCCESS" then
          ui.set_status("Run completed successfully")
          callback(true)
        else
          local msg = state.state_message or "Unknown error"
          ui.show_error("Run failed: " .. result_state .. " - " .. msg)
          callback(false)
        end
      elseif life_cycle == "INTERNAL_ERROR" then
        local msg = state.state_message or "Internal error"
        ui.show_error("Internal error: " .. msg)
        callback(false)
      elseif life_cycle == "SKIPPED" then
        ui.show_error("Run was skipped")
        callback(false)
      else
        ui.set_status("Status: " .. (life_cycle or "unknown") .. "...")
        vim.defer_fn(check, cfg.poll_interval_ms)
      end
    end)
  end

  check()
end

--- Fetch run output
--- @param run_id string
local function fetch_output(run_id)
  exec_cli({
    "runs", "get-output",
    "--run-id", run_id,
  }, function(stdout, exit_code)
    if exit_code ~= 0 then
      return
    end

    local ok, parsed = pcall(vim.json.decode, stdout)
    if ok and type(parsed) == "table" then
      local logs = parsed.logs or ""
      local notebook_output = parsed.notebook_output
        and parsed.notebook_output.result or nil

      if logs ~= "" then
        ui.show_result(logs)
      elseif notebook_output then
        ui.show_result(notebook_output)
      else
        ui.show_result("(no output)")
      end
    else
      -- If not JSON, display raw output
      ui.show_result(stdout ~= "" and stdout or "(no output)")
    end
  end)
end

--- Run the current file on Databricks
function M.run_current_file()
  -- Check CLI availability
  if not config.check_cli() then
    vim.notify("[databricks.nvim] databricks CLI not found in PATH", vim.log.levels.ERROR)
    return
  end

  -- Get and validate file path
  local filepath = vim.api.nvim_buf_get_name(0)
  if not config.validate_local_path(filepath) then
    vim.notify("[databricks.nvim] Current buffer is not a valid .py file", vim.log.levels.ERROR)
    return
  end

  -- Save unsaved changes
  if vim.bo.modified then
    vim.cmd("write")
  end

  -- Get cluster ID
  local cluster_id = cluster.get_cluster_id()
  if not cluster_id then
    vim.notify("[databricks.nvim] No cluster selected. Run :DatabricksClusterSelect first", vim.log.levels.ERROR)
    return
  end

  if not config.validate_cluster_id(cluster_id) then
    vim.notify("[databricks.nvim] Invalid cluster ID format", vim.log.levels.ERROR)
    return
  end

  -- Show output UI
  ui.show_header(filepath, cluster_id)

  -- Execution pipeline: upload → submit → poll → output
  upload_file(filepath, function(dbfs_path)
    if not dbfs_path then
      return
    end

    submit_job(dbfs_path, cluster_id, function(run_id)
      if not run_id then
        return
      end

      poll_run(run_id, function(success)
        if success then
          fetch_output(run_id)
        end
      end)
    end)
  end)
end

--- Re-display the last run output
function M.show_last_output()
  if not M._last_run_id then
    vim.notify("[databricks.nvim] No previous run found", vim.log.levels.WARN)
    return
  end

  ui.open()
  fetch_output(M._last_run_id)
end

return M
