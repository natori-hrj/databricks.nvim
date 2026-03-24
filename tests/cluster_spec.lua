describe("databricks.cluster", function()
  local cluster

  before_each(function()
    package.loaded["databricks.config"] = nil
    package.loaded["databricks.cluster"] = nil

    local config = require("databricks.config")
    config.setup()
    cluster = require("databricks.cluster")
    cluster._selected_cluster_id = nil
  end)

  describe("get_cluster_id", function()
    it("returns nil when nothing is configured or selected", function()
      assert.is_nil(cluster.get_cluster_id())
    end)

    it("returns config cluster_id when set", function()
      local config = require("databricks.config")
      config.setup({ cluster_id = "0123-456789-abcde123" })
      assert.equals("0123-456789-abcde123", cluster.get_cluster_id())
    end)

    it("returns session selection when config has no cluster_id", function()
      cluster._selected_cluster_id = "9999-888888-xyz12345"
      assert.equals("9999-888888-xyz12345", cluster.get_cluster_id())
    end)

    it("prefers config cluster_id over session selection", function()
      local config = require("databricks.config")
      config.setup({ cluster_id = "0123-456789-abcde123" })
      cluster._selected_cluster_id = "9999-888888-xyz12345"
      assert.equals("0123-456789-abcde123", cluster.get_cluster_id())
    end)
  end)

  describe("list", function()
    it("returns error when CLI is not found", function()
      -- Simulate CLI not found
      local config = require("databricks.config")
      local original = config.check_cli
      config.check_cli = function()
        return false
      end

      local result_err
      cluster.list(function(_, err)
        result_err = err
      end)

      assert.is_not_nil(result_err)
      assert.matches("not found", result_err)

      config.check_cli = original
    end)
  end)
end)
