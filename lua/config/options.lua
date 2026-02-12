-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

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

-- 禁用不需要的 provider（消除警告）
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

-- LSP 日志文件大小限制 - 启动时清理过大的日志
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local log_path = vim.fn.stdpath("data") .. "/lsp.log"
    local stat = vim.loop.fs_stat(log_path)
    if stat and stat.size > 10 * 1024 * 1024 then  -- 如果超过 10MB
      -- 删除日志文件（会在下次 LSP 启动时重新创建）
      vim.fn.delete(log_path)
      vim.notify("LSP 日志文件过大已清理", vim.log.levels.INFO)
    end
  end,
})

-- LSP 性能优化
vim.opt.updatetime = 500  -- 减少触发频率（默认 4000ms）
vim.lsp.set_log_level("ERROR")  -- 只记录错误日志（减少日志文件大小）

-- -- 禁用语义高亮（可能导致卡顿）
-- vim.api.nvim_create_autocmd("LspAttach", {
  -- callback = function(args)
    -- local client = vim.lsp.get_client_by_id(args.data.client_id)
    -- if client then
      -- client.server_capabilities.semanticTokensProvider = nil
    -- end
  -- end,
-- })

-- 减少诊断更新频率
vim.diagnostic.config({
  update_in_insert = false,  -- 在插入模式下不更新诊断
  virtual_text = {
    spacing = 4,
    prefix = "●",
  },
})
