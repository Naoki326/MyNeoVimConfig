return {
  -- 配置 LSP
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.omnisharp = {
        -- 手动指定启动命令，确保使用LSP模式
        handlers = {
          ["textDocument/definition"] = function(...)
            return require("omnisharp_extended").handler(...)
          end,
        },
        cmd = { "dotnet", vim.fn.stdpath("data") .. "/mason/packages/omnisharp/libexec/OmniSharp.dll" },
        enable_roslyn_analyzers = true,
        organize_imports_on_format = true,
        enable_import_completion = true,
        -- 添加必要的设置
        settings = {
          FormattingOptions = {
            EnableEditorConfigSupport = true,
            OrganizeImports = true,
          },
          RoslynExtensionsOptions = {
            EnableAnalyzersSupport = true,
            EnableImportCompletion = true,
          },
        },
      }
      return opts
    end,
  },

  -- 配置 Mason 自动安装 LSP 服务器和工具
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "omnisharp", -- C# LSP 服务器
        "csharpier", -- C# 代码格式化工具
        "netcoredbg", -- .NET 调试器
      },
    },
  },

  -- 配置 mason-lspconfig 自动设置
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "omnisharp",
      },
    },
  },
  {
    "Hoffs/omnisharp-extended-lsp.nvim",
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
