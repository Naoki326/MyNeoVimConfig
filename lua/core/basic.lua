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

vim.opt.ignorecase = true
vim.opt.smartcase = true

-- 使用系统的剪切板
vim.opt.clipboard:append("unnamedplus")

-- 设置编码为 utf-8
vim.o.encoding = 'utf-8'
vim.o.fileencoding = 'utf-8'

-- 自动识别文件编码，兼容中文(gbk, gb18030)
vim.o.fileencodings = 'utf-8,gbk,gb18030,gb2312,latin1'

-- 设置默认 shell 为 powershell 7
vim.o.shell = 'pwsh'
vim.o.shellcmdflag = '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;'
vim.o.shellredir = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
vim.o.shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
vim.o.shellquote = ''
vim.o.shellxquote = ''

function my_paste(reg)
    return function(lines)
        --[ 返回 “” 寄存器的内容，用来作为 p 操作符的粘贴物 ]
        local content = vim.fn.getreg('"')
        return vim.split(content, '\n')
    end
end

-- SSH 环境下使用 OSC 52 将剪贴板内容转发到本地终端
-- 要求本地终端支持 OSC 52（Windows Terminal 1.18+、iTerm2、kitty 等）
if vim.env.SSH_CLIENT ~= nil or vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil then
  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
      ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
    },
    paste = {
      -- ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
      -- ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
      ["+"] = my_paste("+"),
      ["*"] = my_paste("*"),
    },
  }
end
