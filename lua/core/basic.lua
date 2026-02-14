vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.cursorline = true
vim.opt.colorcolumn = "120"

vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 0

vim.opt.autoread = true

vim.opt.splitbelow = true
vim.opt.splitright = true

-- 设置默认 shell 为 PowerShell 7
vim.o.shell = 'pwsh'
vim.o.shellcmdflag = '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;'
vim.o.shellredir = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
vim.o.shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
vim.o.shellquote = ''
vim.o.shellxquote = ''

-- 使用 Windows 自带的剪贴板（PowerShell）
vim.g.clipboard = {
  name = "WslClipboard",
  copy = {
    ["+"] = "pwsh.exe -c [Console]::In.ReadToEnd() | Set-Clipboard",
    ["*"] = "pwsh.exe -c [Console]::In.ReadToEnd() | Set-Clipboard",
  },
  paste = {
    ["+"] = "pwsh.exe -c Get-Clipboard",
    ["*"] = "pwsh.exe -c Get-Clipboard",
  },
  cache_enabled = 0,
}
