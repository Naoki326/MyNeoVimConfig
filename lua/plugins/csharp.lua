-- C# 插件配置
return {
  {
    "iabdelkareem/csharp.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "mfussenegger/nvim-dap",
      "Tastyep/structlog.nvim",
    },
    config = function()
      -- 确保 Mason 先初始化
      require("mason").setup()

      require("csharp").setup({
        lsp = {
          -- 使用 omnisharp 作为 LSP
          omnisharp = {
            enable = false,
            cmd_path = nil, -- 自动安装
            default_timeout = 1000,
            -- 性能优化配置
            enable_editor_config_support = false,
            organize_imports = false,
            load_projects_on_demand = false,
            enable_analyzers_support = false, -- 禁用分析器以提高性能
            enable_import_completion = false,
            include_prerelease_sdks = true,
            analyze_open_documents_only = true, -- 只分析打开的文档
            enable_package_auto_restore = true,
            debug = false,
          },
          -- -- 不使用 roslyn (没有开源)
          -- roslyn = {
          --   enable = true,
          --   cmd_path = nil,
          -- },
        },
        logging = {
          level = "ERROR", -- 只记录错误，不记录 INFO 和 WARN
        },
        dap = {
          adapter_name = nil,
        },
      })
    end,
  },
}
