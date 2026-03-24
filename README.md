# databricks.nvim

Neovim plugin for running Python files on Databricks clusters.

## Features

- **`:DatabricksRun`** — Execute the current Python file on a Databricks cluster
- **`:DatabricksClusterList`** — List available clusters
- **`:DatabricksClusterSelect`** — Interactively select a cluster
- **`:DatabricksOutput`** — Re-display the output from the last run

All operations are **async** — your editor is never blocked.

## Requirements

- Neovim >= 0.9
- [Databricks CLI](https://docs.databricks.com/dev-tools/cli/install.html) v0.200+ (authenticated)

## Installation

### lazy.nvim

```lua
{
  "natori/databricks.nvim",
  ft = "python",
  config = function()
    require("databricks").setup({
      -- Databricks CLI profile (~/.databrickscfg section name)
      profile = "DEFAULT",
      -- Cluster ID (nil = select interactively)
      cluster_id = nil,
      -- DBFS upload directory
      upload_path = "dbfs:/tmp/databricks-nvim",
      -- Job completion polling interval (ms)
      poll_interval_ms = 5000,
      -- Output buffer position ("botright", "topleft", "vertical")
      output_position = "botright",
      -- Output buffer height (lines)
      output_height = 15,
    })
  end,
}
```

## Usage

1. Open a Python file
2. Select a cluster: `:DatabricksClusterSelect`
3. Run the file: `:DatabricksRun`
4. View results in the output buffer (opens automatically)

### Keymaps (example)

```lua
vim.keymap.set("n", "<leader>dr", "<cmd>DatabricksRun<cr>", { desc = "Databricks: Run file" })
vim.keymap.set("n", "<leader>dc", "<cmd>DatabricksClusterSelect<cr>", { desc = "Databricks: Select cluster" })
vim.keymap.set("n", "<leader>dl", "<cmd>DatabricksClusterList<cr>", { desc = "Databricks: List clusters" })
vim.keymap.set("n", "<leader>do", "<cmd>DatabricksOutput<cr>", { desc = "Databricks: Show output" })
```

## How It Works

1. **Upload** — Copies the current `.py` file to DBFS via `databricks fs cp`
2. **Submit** — Creates a one-time job run via `databricks jobs submit`
3. **Poll** — Monitors job status via `databricks runs get`
4. **Output** — Fetches results via `databricks runs get-output`

## Security

- No credentials are stored or managed by this plugin — authentication is fully delegated to the Databricks CLI
- All shell arguments are escaped to prevent command injection
- JSON payloads are passed via temp files (not shell interpolation)
- File paths and cluster IDs are validated before use
- Sensitive information (tokens, hosts) is masked in error messages
- Only `.py` files are accepted; path traversal is blocked

## License

MIT
