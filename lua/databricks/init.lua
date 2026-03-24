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

  -- Register default keymaps
  local cfg = config.get()
  local prefix = cfg.keymap_prefix
  if prefix then
    local map = function(key, cmd, desc)
      vim.keymap.set("n", prefix .. key, cmd, { desc = "Databricks: " .. desc })
    end
    map("r", "<cmd>DatabricksRun<cr>", "Run file")
    map("c", "<cmd>DatabricksClusterSelect<cr>", "Select cluster")
    map("l", "<cmd>DatabricksClusterList<cr>", "List clusters")
    map("o", "<cmd>DatabricksOutput<cr>", "Show output")
    map("s", "<cmd>DatabricksClusterStart<cr>", "Start cluster")
    map("x", "<cmd>DatabricksClusterStop<cr>", "Stop cluster")
  end
end

-- Public API
M.run = run.run_current_file
M.output = run.show_last_output
M.cluster_list = cluster.show_list
M.cluster_select = cluster.select
M.cluster_start = cluster.start
M.cluster_stop = cluster.stop

return M
