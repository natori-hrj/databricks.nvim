local config = require("databricks.config")
local cluster = require("databricks.cluster")
local run = require("databricks.run")

local M = {}

--- Initialize plugin
--- @param opts table|nil
function M.setup(opts)
  config.setup(opts)

  if not config.check_cli() then
    vim.notify(
      "[databricks.nvim] databricks CLI not found. Install: https://docs.databricks.com/dev-tools/cli/install.html",
      vim.log.levels.WARN
    )
  end
end

-- Public API
M.run = run.run_current_file
M.output = run.show_last_output
M.cluster_list = cluster.show_list
M.cluster_select = cluster.select

return M
