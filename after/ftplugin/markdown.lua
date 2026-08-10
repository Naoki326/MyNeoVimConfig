-- follow-md-links 的 ftplugin 映射（自包含版，替代原插件）
-- 光标在 markdown 链接（标签或 URL）上按 <CR> 或 gf 跟随：
--   本地文件 → nvim 打开；web 链接 → 系统浏览器
-- gf 优先解析 markdown 链接，找不到链接时回退到内置 gf 行为
-- 原插件 jghauser/follow-md-links.nvim 因 Windows 兼容问题（4 个 bug）
-- 已自包含到 lua/follow-md-links/init.lua，这里只负责注册键位。
local map = vim.api.nvim_buf_set_keymap
local opts = { noremap = true, silent = true }

map(0, "n", "<cr>", ':lua require("follow-md-links").follow_link()<cr>', opts)
map(0, "n", "gf", ':lua require("follow-md-links").gf()<cr>', opts)

-- 返回上一个文件（配合链接跟随使用）
map(0, "n", "<bs>", ":edit #<cr>", opts)
