local config = require("databricks.config")

local M = {}

--- Output buffer ID
M._bufnr = nil
--- Output window ID
M._winnr = nil

--- Get or create the output buffer
--- @return number bufnr
function M.get_buf()
  if M._bufnr and vim.api.nvim_buf_is_valid(M._bufnr) then
    return M._bufnr
  end

  M._bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = M._bufnr })
  vim.api.nvim_set_option_value("bufhidden", "hide", { buf = M._bufnr })
  vim.api.nvim_set_option_value("swapfile", false, { buf = M._bufnr })
  vim.api.nvim_set_option_value("filetype", "databricks-output", { buf = M._bufnr })
  vim.api.nvim_buf_set_name(M._bufnr, "[databricks-output]")

  return M._bufnr
end

--- Open the output window
function M.open()
  local bufnr = M.get_buf()
  local cfg = config.get()

  -- Focus existing window if already open
  if M._winnr and vim.api.nvim_win_is_valid(M._winnr) then
    vim.api.nvim_set_current_win(M._winnr)
    return
  end

  vim.cmd(cfg.output_position .. " " .. cfg.output_height .. "split")
  M._winnr = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(M._winnr, bufnr)
  vim.api.nvim_set_option_value("number", false, { win = M._winnr })
  vim.api.nvim_set_option_value("relativenumber", false, { win = M._winnr })
  vim.api.nvim_set_option_value("wrap", true, { win = M._winnr })
end

--- Clear buffer contents
function M.clear()
  local bufnr = M.get_buf()
  vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
  vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
end

--- Append lines to the buffer
--- @param lines string|string[]
function M.append(lines)
  if type(lines) == "string" then
    lines = vim.split(lines, "\n", { plain = true })
  end

  local bufnr = M.get_buf()
  vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })

  local count = vim.api.nvim_buf_line_count(bufnr)
  -- Start from the first line if buffer is empty
  local last_line = vim.api.nvim_buf_get_lines(bufnr, count - 1, count, false)
  if count == 1 and last_line[1] == "" then
    vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, lines)
  else
    vim.api.nvim_buf_set_lines(bufnr, count, count, false, lines)
  end

  vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })

  -- Auto-scroll to bottom
  if M._winnr and vim.api.nvim_win_is_valid(M._winnr) then
    local new_count = vim.api.nvim_buf_line_count(bufnr)
    vim.api.nvim_win_set_cursor(M._winnr, { new_count, 0 })
  end
end

--- Display status header
--- @param file string File path
--- @param cluster_id string Cluster ID
function M.show_header(file, cluster_id)
  M.clear()
  M.open()
  M.append({
    "━━━ Databricks Run ━━━",
    "File:    " .. vim.fn.fnamemodify(file, ":t"),
    "Cluster: " .. cluster_id,
    "━━━━━━━━━━━━━━━━━━━━━━",
    "",
  })
end

--- Update status line
--- @param status string
function M.set_status(status)
  M.append({ "▸ " .. status })
end

--- Display error message
--- @param msg string
function M.show_error(msg)
  M.append({ "", "✗ ERROR: " .. msg })
end

--- Display successful run output
--- @param output string
function M.show_result(output)
  M.append({ "", "━━━ Output ━━━", "" })
  M.append(output)
  M.append({ "", "━━━ Done ━━━" })
end

return M
