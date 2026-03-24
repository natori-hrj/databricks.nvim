local M = {}

--- Default configuration
local defaults = {
  -- Databricks CLI profile name (section in ~/.databrickscfg)
  profile = "DEFAULT",
  -- Cluster ID to use (nil = select interactively)
  cluster_id = nil,
  -- DBFS upload destination directory
  upload_path = "dbfs:/tmp/databricks-nvim",
  -- Job completion polling interval (milliseconds)
  poll_interval_ms = 5000,
  -- Output buffer position ("botright", "topleft", "vertical")
  output_position = "botright",
  -- Output buffer height (lines)
  output_height = 15,
  -- Keymap prefix (set to false to disable default keymaps)
  keymap_prefix = "<leader>d",
}

M._config = vim.deepcopy(defaults)

--- Validate cluster ID format (Databricks format: digits-digits-alphanumeric)
--- @param id string
--- @return boolean
function M.validate_cluster_id(id)
  if type(id) ~= "string" or id == "" then
    return false
  end
  -- Databricks cluster ID: e.g. "0123-456789-abcde123"
  return id:match("^%d+%-%d+%-[%w]+$") ~= nil
end

--- Validate DBFS path
--- @param path string
--- @return boolean
function M.validate_dbfs_path(path)
  if type(path) ~= "string" or path == "" then
    return false
  end
  -- Must start with dbfs:/ and contain no dangerous characters
  if not path:match("^dbfs:/") then
    return false
  end
  -- Prevent path traversal
  if path:match("%.%.") then
    return false
  end
  -- Reject shell metacharacters
  if path:match("[;|&$`\"'\\%(%){}<>!#%%]") then
    return false
  end
  return true
end

--- Validate local file path
--- @param path string
--- @return boolean
function M.validate_local_path(path)
  if type(path) ~= "string" or path == "" then
    return false
  end
  -- Prevent path traversal
  if path:match("%.%.") then
    return false
  end
  -- Only allow .py files
  if not path:match("%.py$") then
    return false
  end
  -- Check file existence
  return vim.fn.filereadable(path) == 1
end

--- Validate profile name
--- @param profile string
--- @return boolean
function M.validate_profile(profile)
  if type(profile) ~= "string" or profile == "" then
    return false
  end
  -- Only allow alphanumeric, hyphens, and underscores
  return profile:match("^[%w%-_]+$") ~= nil
end

--- Check if databricks CLI is available
--- @return boolean
function M.check_cli()
  return vim.fn.executable("databricks") == 1
end

--- Apply configuration
--- @param opts table|nil
function M.setup(opts)
  if opts then
    M._config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts)
  end

  -- Validation
  if M._config.cluster_id and not M.validate_cluster_id(M._config.cluster_id) then
    vim.notify("[databricks.nvim] Invalid cluster_id format", vim.log.levels.ERROR)
    M._config.cluster_id = nil
  end

  if not M.validate_dbfs_path(M._config.upload_path) then
    vim.notify("[databricks.nvim] Invalid upload_path, using default", vim.log.levels.WARN)
    M._config.upload_path = defaults.upload_path
  end

  if not M.validate_profile(M._config.profile) then
    vim.notify("[databricks.nvim] Invalid profile name, using DEFAULT", vim.log.levels.WARN)
    M._config.profile = defaults.profile
  end
end

--- Get current configuration
--- @return table
function M.get()
  return M._config
end

return M
