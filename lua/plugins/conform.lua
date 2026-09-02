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
    -- 注意："currline" 而非 "line" —— g@ 的 linewise motion 也传 "line"，会撞分支
    { "==", function() _G.conform_format_op("currline") end, desc = "Format line" },
    { "=", function() _G.conform_format_op("visual") end, mode = "x", desc = "Format selection" },
    { "=", function() vim.o.operatorfunc = "v:lua.conform_format_op"; return "g@" end, expr = true, desc = "Format operator" },
  },
  init = function()
    _G.conform_format_op = function(type)
      local conform = require("conform")
      local range = nil
      if type == "visual" then
        -- Neovim 0.12：visual 模式激活期间 '< '> marks 尚未写入
        -- （nvim_buf_get_mark 返回 {0,0}，算出的 range 是 {-1,0} 非法）。
        -- 不传 range，conform 内部用 getpos("v") 自动检测当前选区（见 conform/init.lua range_from_selection）
        range = nil
      elseif type == "currline" then
        -- == ：格式化当前行
        local l = vim.fn.line(".") - 1
        range = { start = { l, 0 }, ["end"] = { l, 0 } }
      else
        -- operator-pending (g@)：type 为 linewise/charwise/blockwise motion 类型，
        -- '[ '] marks 已由 g@ 设置。用 getpos（1-based）转 conform 的 0-based range
        local s = vim.fn.getpos("'[")
        local e = vim.fn.getpos("']")
        range = { start = { s[2] - 1, s[3] - 1 }, ["end"] = { e[2] - 1, e[3] - 1 } }
      end
      conform.format({ bufnr = 0, range = range, lsp_fallback = true })
    end
  end,
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "isort", "black" },
      -- 嵌套 {} 语法（"依次尝试第一个可用的"）已被 conform ≥2025-01 移除，
      -- 改用 stop_after_first；json 同样交给 prettier
      javascript = { "prettierd", "prettier", stop_after_first = true },
      json = { "prettierd", "prettier", stop_after_first = true },
    },
    format_on_save = {
      timeout_ms = 500,
      lsp_fallback = true,
    },
  },
}
