-- bootstrap lazy.nvim, LazyVim and your plugins

vim.env.HTTP_PROXY = "http://127.0.0.1:7897"
vim.env.HTTPS_PROXY = "http://127.0.0.1:7897"
vim.env.NO_PROXY = "localhost,127.0.0.1"

require("core.basic")
require("core.autocmds")
require("core.keymap")
require("core.lazy")

-- DAP 初始化：在 VeryLazy 后统一执行，确保所有插件已加载
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function() require("core.dap").setup() end,
})
