describe("databricks.run", function()
  local run, config, cluster

  before_each(function()
    package.loaded["databricks.config"] = nil
    package.loaded["databricks.cluster"] = nil
    package.loaded["databricks.ui"] = nil
    package.loaded["databricks.run"] = nil

    config = require("databricks.config")
    config.setup()
    cluster = require("databricks.cluster")
    run = require("databricks.run")
  end)

  describe("run_current_file", function()
    it("shows error when CLI is not found", function()
      local original = config.check_cli
      config.check_cli = function()
        return false
      end

      local notified = false
      local original_notify = vim.notify
      vim.notify = function(msg, level)
        if msg:match("CLI not found") and level == vim.log.levels.ERROR then
          notified = true
        end
      end

      run.run_current_file()
      assert.is_true(notified)

      config.check_cli = original
      vim.notify = original_notify
    end)

    it("shows error when no cluster is selected", function()
      local original_cli = config.check_cli
      config.check_cli = function()
        return true
      end

      -- Create a .py buffer
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      vim.api.nvim_buf_set_name(buf, "/tmp/test_databricks_run.py")

      -- Create the file on disk (validate_local_path checks filereadable)
      local f = io.open("/tmp/test_databricks_run.py", "w")
      if f then
        f:write("print('hello')\n")
        f:close()
      end

      local notified = false
      local original_notify = vim.notify
      vim.notify = function(msg, level)
        if msg:match("No cluster selected") and level == vim.log.levels.ERROR then
          notified = true
        end
      end

      run.run_current_file()
      assert.is_true(notified)

      -- Cleanup
      os.remove("/tmp/test_databricks_run.py")
      vim.api.nvim_buf_delete(buf, { force = true })
      config.check_cli = original_cli
      vim.notify = original_notify
    end)

    it("shows error for non-Python files", function()
      local original_cli = config.check_cli
      config.check_cli = function()
        return true
      end

      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      vim.api.nvim_buf_set_name(buf, "/tmp/test.txt")

      local notified = false
      local original_notify = vim.notify
      vim.notify = function(msg, level)
        if msg:match("not a valid .py file") and level == vim.log.levels.ERROR then
          notified = true
        end
      end

      run.run_current_file()
      assert.is_true(notified)

      vim.api.nvim_buf_delete(buf, { force = true })
      config.check_cli = original_cli
      vim.notify = original_notify
    end)
  end)

  describe("show_last_output", function()
    it("shows warning when no previous run exists", function()
      run._last_run_id = nil

      local notified = false
      local original_notify = vim.notify
      vim.notify = function(msg, level)
        if msg:match("No previous run") and level == vim.log.levels.WARN then
          notified = true
        end
      end

      run.show_last_output()
      assert.is_true(notified)

      vim.notify = original_notify
    end)
  end)
end)
