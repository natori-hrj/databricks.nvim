describe("databricks.ui", function()
  local ui

  before_each(function()
    package.loaded["databricks.config"] = nil
    package.loaded["databricks.ui"] = nil

    local config = require("databricks.config")
    config.setup()
    ui = require("databricks.ui")
    ui._bufnr = nil
    ui._winnr = nil
  end)

  after_each(function()
    -- Clean up buffers after test
    if ui._bufnr and vim.api.nvim_buf_is_valid(ui._bufnr) then
      vim.api.nvim_buf_delete(ui._bufnr, { force = true })
    end
    if ui._winnr and vim.api.nvim_win_is_valid(ui._winnr) then
      vim.api.nvim_win_close(ui._winnr, true)
    end
  end)

  describe("get_buf", function()
    it("creates a new buffer", function()
      local bufnr = ui.get_buf()
      assert.is_number(bufnr)
      assert.is_true(vim.api.nvim_buf_is_valid(bufnr))
    end)

    it("returns the same buffer on subsequent calls", function()
      local buf1 = ui.get_buf()
      local buf2 = ui.get_buf()
      assert.equals(buf1, buf2)
    end)

    it("sets correct buffer options", function()
      local bufnr = ui.get_buf()
      assert.equals("nofile", vim.api.nvim_get_option_value("buftype", { buf = bufnr }))
      assert.equals(false, vim.api.nvim_get_option_value("swapfile", { buf = bufnr }))
      assert.equals("databricks-output", vim.api.nvim_get_option_value("filetype", { buf = bufnr }))
    end)
  end)

  describe("clear", function()
    it("empties the buffer", function()
      local bufnr = ui.get_buf()
      vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "line1", "line2" })
      vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })

      ui.clear()

      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      assert.equals(1, #lines)
      assert.equals("", lines[1])
    end)
  end)

  describe("append", function()
    it("appends string lines to buffer", function()
      ui.get_buf()
      ui.append({ "hello", "world" })

      local bufnr = ui.get_buf()
      vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })

      assert.equals("hello", lines[1])
      assert.equals("world", lines[2])
    end)

    it("appends a single string by splitting on newlines", function()
      ui.get_buf()
      ui.append("line1\nline2")

      local bufnr = ui.get_buf()
      vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })

      assert.equals("line1", lines[1])
      assert.equals("line2", lines[2])
    end)
  end)

  describe("show_header", function()
    it("displays file and cluster info", function()
      ui.show_header("/path/to/script.py", "0123-456789-abc12345")

      local bufnr = ui.get_buf()
      vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })

      local content = table.concat(lines, "\n")
      assert.matches("script%.py", content)
      assert.matches("0123%-456789%-abc12345", content)
    end)
  end)
end)
