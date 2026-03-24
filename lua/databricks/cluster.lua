local config = require("databricks.config")

local M = {}

--- Currently selected cluster ID (persisted during session)
M._selected_cluster_id = nil

--- Get the active cluster ID (config takes priority over session selection)
--- @return string|nil
function M.get_cluster_id()
  local cfg = config.get()
  return cfg.cluster_id or M._selected_cluster_id
end

--- Fetch cluster list asynchronously
--- @param callback fun(clusters: table[]|nil, err: string|nil)
function M.list(callback)
  if not config.check_cli() then
    callback(nil, "databricks CLI not found in PATH")
    return
  end

  local cfg = config.get()
  local stdout_chunks = {}
  local stderr_chunks = {}

  vim.fn.jobstart({
    "databricks", "clusters", "list",
    "--profile", cfg.profile,
    "--output", "json",
  }, {
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
        if exit_code ~= 0 then
          local err_msg = table.concat(stderr_chunks, "\n")
          -- Mask sensitive information (tokens, etc.) from error messages
          err_msg = err_msg:gsub("[Tt]oken%s*[=:]%s*%S+", "token=***")
          callback(nil, "CLI error (exit " .. exit_code .. "): " .. err_msg)
          return
        end

        local raw = table.concat(stdout_chunks, "\n")
        local ok, parsed = pcall(vim.json.decode, raw)
        if not ok or type(parsed) ~= "table" then
          callback(nil, "Failed to parse cluster list JSON")
          return
        end

        -- Clusters may be a top-level array or under .clusters key
        local clusters = parsed
        if parsed.clusters then
          clusters = parsed.clusters
        end

        if type(clusters) ~= "table" then
          callback(nil, "Unexpected cluster list format")
          return
        end

        callback(clusters, nil)
      end)
    end,
  })
end

--- Interactively select a cluster via vim.ui.select
function M.select()
  M.list(function(clusters, err)
    if err then
      vim.notify("[databricks.nvim] " .. err, vim.log.levels.ERROR)
      return
    end

    if not clusters or #clusters == 0 then
      vim.notify("[databricks.nvim] No clusters found", vim.log.levels.WARN)
      return
    end

    -- Build display labels
    local items = {}
    for _, c in ipairs(clusters) do
      table.insert(items, {
        label = string.format("%s [%s] (%s)",
          c.cluster_name or "unknown",
          c.state or "?",
          c.cluster_id or "?"
        ),
        cluster = c,
      })
    end

    vim.ui.select(items, {
      prompt = "Select Databricks Cluster:",
      format_item = function(item)
        return item.label
      end,
    }, function(choice)
      if not choice then
        return
      end

      local id = choice.cluster.cluster_id
      if not id or not config.validate_cluster_id(id) then
        vim.notify("[databricks.nvim] Invalid cluster ID from API response", vim.log.levels.ERROR)
        return
      end

      M._selected_cluster_id = id
      vim.notify("[databricks.nvim] Selected: " .. choice.label, vim.log.levels.INFO)
    end)
  end)
end

--- Display cluster list (no selection)
function M.show_list()
  M.list(function(clusters, err)
    if err then
      vim.notify("[databricks.nvim] " .. err, vim.log.levels.ERROR)
      return
    end

    if not clusters or #clusters == 0 then
      vim.notify("[databricks.nvim] No clusters found", vim.log.levels.WARN)
      return
    end

    local lines = { "Databricks Clusters:", "" }
    for _, c in ipairs(clusters) do
      table.insert(lines, string.format("  %-30s %-12s %s",
        c.cluster_name or "unknown",
        c.state or "?",
        c.cluster_id or "?"
      ))
    end

    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end)
end

return M
