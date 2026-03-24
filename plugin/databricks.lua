if vim.g.loaded_databricks then
  return
end
vim.g.loaded_databricks = true

vim.api.nvim_create_user_command("DatabricksRun", function()
  require("databricks").run()
end, { desc = "Run current Python file on Databricks cluster" })

vim.api.nvim_create_user_command("DatabricksClusterList", function()
  require("databricks").cluster_list()
end, { desc = "List Databricks clusters" })

vim.api.nvim_create_user_command("DatabricksClusterSelect", function()
  require("databricks").cluster_select()
end, { desc = "Select a Databricks cluster" })

vim.api.nvim_create_user_command("DatabricksOutput", function()
  require("databricks").output()
end, { desc = "Show output from last Databricks run" })
