-- 数学公式图片预览：在 Nebula 里把光标下的公式渲染成真排版图片显示
-- 依赖：~/AppData/Local/nvim/bin/math_render.py（matplotlib 渲染 + OSC 1337 输出）
-- 用法：<leader>mf 预览当前光标所在公式；<leader>mF 预览整个文件所有公式

local M = {}

local PY = vim.fn.stdpath('config') .. '/bin/math_render.py'

-- 找 python 解释器
local PYTHON = nil
for _, c in ipairs({ 'python', 'python3' }) do
  if vim.fn.executable(c) == 1 then
    PYTHON = c
    break
  end
end

-- 提取当前光标所在公式（纯文本正则，不依赖 treesitter 注入时序）
function M._extract_formula()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()

  -- 1) 当前行内 $...$ 公式（光标所在的那一个）
  local start = 1
  while true do
    local a, b = line:find('%$[^%$]+%$', start)
    if not a then break end
    if col >= a - 1 and col <= b - 1 then
      return line:sub(a + 1, b - 1)
    end
    start = b + 1
  end

  -- 2) 块级公式：光标位于 $$...$$ 块内
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local in_block = false
  local block_start = 0
  for i, l in ipairs(lines) do
    if l:match('^%s*%$%$') then
      if not in_block then
        in_block = true
        block_start = i
      else
        if row >= block_start and row <= i then
          local block = {}
          for j = block_start + 1, i - 1 do
            block[#block + 1] = lines[j]:gsub('^%s+', '')
          end
          if #block > 0 then return table.concat(block, ' ') end
        end
        in_block = false
      end
    end
  end
  -- 光标恰好在 $$ 定界行上：尝试取相邻块
  if row >= block_start and in_block then
    local block = {}
    for j = block_start + 1, math.min(row + 2, #lines) do
      if lines[j]:match('%$%$') then break end
      block[#block + 1] = lines[j]:gsub('^%s+', '')
    end
    if #block > 0 then return table.concat(block, ' ') end
  end

  return nil
end

-- 渲染并输出 OSC 1337 图片序列到终端
-- 用 :! 外部命令模式：nvim 把终端交给 shell，OSC 序列绕过 nvim 渲染层直达 Nebula
function M._show(formula, width)
  vim.cmd('!python ' .. vim.fn.shellescape(PY) .. ' ' .. vim.fn.shellescape(formula) .. ' --width ' .. width)
end

-- 预览当前公式
function M.preview()
  local formula = M._extract_formula()
  if not formula or formula == '' then
    vim.notify('未找到公式（光标需在 $...$ 或 $$...$$ 内）', vim.log.levels.WARN)
    return
  end
  M._show(formula, '55%')
  vim.notify('公式: ' .. formula:gsub('%s+', ' '):sub(1, 60), vim.log.levels.INFO)
end

-- 预览当前文件所有公式
function M.preview_all()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local formulas = {}
  for i, l in ipairs(lines) do
    for f in l:gmatch('%$([^%$]+)%$') do
      formulas[#formulas + 1] = { formula = f, row = i }
    end
    if l:match('%$%$') then
      -- 收集多行块
      local block = {}
      local j = i
      while j <= #lines do
        local ll = lines[j]
        if ll:match('%$%$') and #block > 0 then break end
        block[#block + 1] = ll:gsub('%$%$', ''):gsub('^%s+', '')
        j = j + 1
      end
      if #block > 0 then
        formulas[#formulas + 1] = { formula = table.concat(block, ' '), row = i }
      end
    end
  end
  if #formulas == 0 then
    vim.notify('文件中没有公式', vim.log.levels.WARN)
    return
  end
  for _, item in ipairs(formulas) do
    M._show(item.formula, '45%')
  end
  vim.notify('已渲染 ' .. #formulas .. ' 个公式（滚动查看）', vim.log.levels.INFO)
end

-- 设置快捷键（已移除：nvim 无法向 Nebula 输出原始 OSC 1337 序列，图片预览不可行）
function M.setup()
end

M.setup()
return M
