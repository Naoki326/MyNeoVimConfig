return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      -- 允许手动格式化 (Leader+f)
      "<leader>f",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = "",
      desc = "Format buffer",
    },
  },
  opts = {
    -- 在这里配置格式化工具
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "isort", "black" },
      javascript = { { "prettierd", "prettier" } },
    },
    -- 核心：保存时自动格式化
    format_on_save = {
      timeout_ms = 500,
      lsp_fallback = true, -- 如果没有专用格式化工具，使用LSP
    },
  },
}
