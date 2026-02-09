-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- 使用 Windows 自带的剪贴板（PowerShell）
vim.g.clipboard = {
  name = "WslClipboard",
  copy = {
    ["+"] = "powershell.exe -c [Console]::In.ReadToEnd() | Set-Clipboard",
    ["*"] = "powershell.exe -c [Console]::In.ReadToEnd() | Set-Clipboard",
  },
  paste = {
    ["+"] = "powershell.exe -c Get-Clipboard",
    ["*"] = "powershell.exe -c Get-Clipboard",
  },
  cache_enabled = 0,
}

-- 禁用不需要的 provider（消除警告）
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
