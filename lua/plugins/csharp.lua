
return {
  "iabdelkareem/csharp.nvim",
  dependencies = {
    "mason-org/mason.nvim", -- Required, automatically installs omnisharp
    "mfussenegger/nvim-dap",
    "Tastyep/structlog.nvim", -- Optional, but highly recommended for debugging
  },
  config = function ()
      require("mason").setup( -- Mason setup must run before csharp, only if you want to use omnisharp
      {
        lsp = {
          -- 使用 omnisharp 作为 LSP
          omnisharp = {
            enable = true,
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
          roslyn = {
            enable = false,
            cmd_path = nil,
          },
        },
        logging = {
          level = "ERROR", -- 只记录错误，不记录 INFO 和 WARN
        },
        dap = {
          adapter_name = nil,
        },
      })
  end
}
