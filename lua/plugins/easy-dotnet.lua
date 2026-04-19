return {
  "GustavEikaas/easy-dotnet.nvim",
  ft = { "cs", "csproj", "sln", "props", "fs", "fsproj" },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "mfussenegger/nvim-dap",
    "folke/snacks.nvim",
  },
  config = function()
    local dotnet = require("easy-dotnet")
    local dap_config = require("core.dap_config")

    dotnet.setup({
      managed_terminal = {
        auto_hide = true,
        auto_hide_delay = 1000,
      },

      lsp = {
        enabled = false,
      },

      debugger = {
        bin_path = nil,
        console = "integratedTerminal",
        apply_value_converters = true,
        -- 只有选择 easydotnet 模式时才让 easy-dotnet 注册 DAP 适配器
        auto_register_dap = dap_config.debugger == "easydotnet",
      },

      test_runner = {
        auto_start_testrunner = true,
        hide_legend = false,
        viewmode = "float",
        icons = {
          passed = "",
          skipped = "",
          failed = "",
          success = "",
          reload = "",
          test = "",
          sln = "󰘐",
          project = "󰘐",
          dir = "",
          package = "",
          class = "",
          build_failed = "󰒡",
        },
      },

      picker = "snacks",
      background_scanning = true,
    })

    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { desc = "Dotnet: " .. desc })
    end

    -- 打开 easy-dotnet 命令选择器（替代不存在的 menu()）
    map("<leader>nm", function() vim.cmd("Dotnet") end, "Menu")

    -- 基础操作（对应 Dotnet 子命令）
    map("<leader>nb", function() dotnet.build() end, "Build")
    map("<leader>nB", function() vim.cmd("Dotnet build solution") end, "Build Solution")
    map("<leader>nr", function() dotnet.run() end, "Run")
    map("<leader>nR", function() dotnet.restore() end, "Restore")
    map("<leader>nt", function() dotnet.test() end, "Test")
    map("<leader>nT", function() vim.cmd("Dotnet test solution") end, "Test Solution")
    map("<leader>nc", function() dotnet.clean() end, "Clean")
    map("<leader>ns", function() dotnet.secrets() end, "User Secrets")

    -- 其他常用功能
    map("<leader>nd", function() dotnet.debug() end, "Debug")
    map("<leader>nw", function() dotnet.watch() end, "Watch")
    map("<leader>np", function() vim.cmd("Dotnet project view") end, "Project View")
    map("<leader>nP", function() dotnet.pack() end, "Pack")
    map("<leader>no", function() dotnet.outdated() end, "Outdated Packages")
    map("<leader>nn", function() dotnet.new() end, "New Item")
    map("<leader>nA", function() vim.cmd("Dotnet add package") end, "Add Package")
    map("<leader>nX", function() vim.cmd("Dotnet remove package") end, "Remove Package")

    -- Test runner
    map("<leader>nu", function() dotnet.testrunner() end, "Test Runner")

    -- 解决方案管理
    map("<leader>nv", function() vim.cmd("Dotnet solution select") end, "Select Solution")

    -- LSP 控制（备用）
    map("<leader>nS", function() vim.cmd("Dotnet _server restart") end, "Restart easy-dotnet Server")
  end,
}
