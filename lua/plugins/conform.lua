return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>f",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = "",
      desc = "Format buffer",
    },
    -- = 操作符：使用 conform 格式化替代 Treesitter indent
    { "==", function() _G.conform_format_op("line") end, desc = "Format line" },
    { "=", function() _G.conform_format_op("visual") end, mode = "x", desc = "Format selection" },
    { "=", function() vim.o.operatorfunc = "v:lua.conform_format_op"; return "g@" end, expr = true, desc = "Format operator" },
  },
  init = function()
    _G.conform_format_op = function(type)
      local conform = require("conform")
      local range = nil
      if type == "line" then
        local l = vim.fn.line(".") - 1
        range = { start = { l, 0 }, ["end"] = { l, 0 } }
      elseif type == "visual" then
        local s = vim.api.nvim_buf_get_mark(0, "<")
        local e = vim.api.nvim_buf_get_mark(0, ">")
        range = { start = { s[1] - 1, s[2] }, ["end"] = { e[1] - 1, e[2] } }
      else
        -- operator-pending mode: g@ sets '[ and '] marks
        local s = vim.api.nvim_buf_get_mark(0, "[")
        local e = vim.api.nvim_buf_get_mark(0, "]")
        range = { start = { s[1] - 1, s[2] }, ["end"] = { e[1] - 1, e[2] } }
      end
      conform.format({ bufnr = 0, range = range, lsp_fallback = true })
    end
  end,
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "isort", "black" },
      javascript = { { "prettierd", "prettier" } },
    },
    format_on_save = {
      timeout_ms = 500,
      lsp_fallback = true,
    },
  },
}
