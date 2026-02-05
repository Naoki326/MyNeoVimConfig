return {
  -- 配置 LSP
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- C# LSP 服务器
        omnisharp = {
          cmd = { "omnisharp" },
          enable_roslyn_analyzers = true,
          organize_imports_on_format = true,
          enable_import_completion = true,
        },
      },
    },
  },

  -- 配置 Mason 自动安装 LSP 服务器和工具
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "omnisharp",    -- C# LSP 服务器
        "csharpier",    -- C# 代码格式化工具
        "netcoredbg",   -- .NET 调试器
      },
    },
  },

  -- 配置格式化工具
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        cs = { "csharpier" },
      },
    },
  },
}
