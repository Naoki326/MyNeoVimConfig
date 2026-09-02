--
-- FOLLOW MD LINKS
--

local fn = vim.fn
local cmd = vim.cmd
local treesitter = require("vim.treesitter")

local sysname = vim.uv.os_uname().sysname

local is_windows = sysname == "Windows_NT"
local is_macos = sysname == "Darwin"
local is_linux = sysname == "Linux"

local block_parser
local block_tree
local block_root
local inline_parser
local inline_tree
local inline_root

local function get_reference_link_destination(link_label)
  local parsed_query = vim.treesitter.query.parse("markdown", [[
  (link_reference_definition
    (link_label) @label (#eq? @label "]] .. link_label .. [[")
    (link_destination) @link_destination)
  ]])
  -- Problem with handling whitespace in filenames elegently is with this iter_matches
  for _, captures, _ in parsed_query:iter_matches(block_root, 0) do
    -- Prior to Neovim 0.11, `match` in `Query:iter_matches()` referred to a single match
    -- https://github.com/neovim/neovim/commit/bd5008de07d29a6457ddc7fe13f9f85c9c4619d2
    local match
    if vim.fn.has('nvim-0.10') == 0 then
      match = captures[2]
    else
      assert(#captures[2] == 1)
      match = captures[2][1]
    end
    local node_text = treesitter.get_node_text(match, 0)
    -- Kludgy method right now is to require that filenames with spaces are wrapped in <>,
    -- which are stripped out after the matching is complete
    return string.gsub(node_text, "[<>]", "")
  end
end

local function get_inline_node_at_cursor(row, col)
  -- Find the block node at the cursor
  local block_node = block_root:named_descendant_for_range(row, col, row, col)
  if not block_node then return nil end

  -- Find the 'inline' child node (递归查找，支持表格单元格等容器)
  local function find_inline(node)
    if not node then return nil end
    if node:type() == "inline" then return node end
    for i = 0, node:named_child_count() - 1 do
      local found = find_inline(node:named_child(i))
      if found then return found end
    end
    return nil
  end
  local inline_node = find_inline(block_node)
  -- 表格单元格等容器：block parser 里没有 inline 子节点，
  -- 直接退化用 inline parser 找光标处节点（表格内容由 injections 单独解析）
  local inline_cursor_node = inline_root:named_descendant_for_range(row, col, row, col)
  if inline_node then
    -- 防御：markdown_inline parser 会把代码围栏结束行（如 ```）之后的正文
    -- 误并进一个跨多行的巨型 code_span（围栏干扰 bug）。此时 inline 节点
    -- 的 range 远大于光标所在段落，链接信息已丢失，需要单独解析当前行。
    if inline_cursor_node then
      local sr, sc, er, ec = inline_cursor_node:range()
      if (sr < row and er > row) or inline_cursor_node:type() == "code_span" and (er - sr) > 0 then
        return nil
      end
    end
    return inline_cursor_node
  end
  -- 找不到 inline 节点时，只要光标处是链接相关节点就直接返回
  if inline_cursor_node then
    local t = inline_cursor_node:type()
    if t == "link_text" or t == "link_destination" or t == "inline_link"
      or t == "link_label" or t == "shortcut_link" or t == "uri_autolink" then
      return inline_cursor_node
    end
  end
  return nil
end

local function get_link_destination()
  block_parser = vim.treesitter.get_parser(0, "markdown")
  inline_parser = vim.treesitter.get_parser(0, "markdown_inline")
  if not block_parser or not inline_parser then
    return
  end
  block_tree = block_parser:parse()[1]
  block_root = block_tree:root()
  inline_tree = inline_parser:parse()[1]
  inline_root = inline_tree:root()

  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]

  local node_at_cursor = get_inline_node_at_cursor(row, col)
  -- 围栏干扰防御：inline parser 全局解析失败时（巨型 code_span 吞掉链接），
  -- 回退为单独解析光标所在行文本，链接节点即可正常解析。
  -- 注意：get_string_parser 返回的节点 range 基于行文本字符串（行内 0-indexed），
  -- 不能直接用 get_node_text(node, bufnr) 读 buffer，需从行文本里截取。
  local line_fallback = nil -- { node = <TSNode>, text = <string> }
  if not node_at_cursor then
    local line_text = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
    if line_text then
      local ok_p, line_parser = pcall(vim.treesitter.get_string_parser, line_text, "markdown_inline")
      if ok_p then
        local line_root = line_parser:parse()[1]:root()
        local line_node = line_root:named_descendant_for_range(0, col, 0, col)
        if line_node and line_node:type() ~= "code_span" then
          node_at_cursor = line_node
          line_fallback = { node = line_node, text = line_text }
        end
      end
    end
  end
  if not node_at_cursor then
    return
  end

  local parent_node = node_at_cursor and node_at_cursor:parent()
  if not (node_at_cursor and parent_node) then
    return
  end
  -- 从节点取文本：line_fallback 时节点基于行字符串解析，需从行文本截取；
  -- 否则从 buffer 读取。
  local function node_text(node)
    if line_fallback then
      local sr, sc, er, ec = node:range()
      return line_fallback.text:sub(sc + 1, ec)
    end
    return treesitter.get_node_text(node, bufnr)
  end
  if node_at_cursor:type() == "link_destination" then
    return vim.split(node_text(node_at_cursor), "\n")[1]
  elseif node_at_cursor:type() == "shortcut_link" then
    local link_text = vim.split(node_text(node_at_cursor), "\n")[1]
    return get_reference_link_destination(link_text)
  elseif node_at_cursor:type() == "link_text" then
    if node_at_cursor:parent():type() == "shortcut_link" then
      local link_text = vim.split(node_text(node_at_cursor:parent()), "\n")[1]
      return get_reference_link_destination(link_text)
    end
    local parent = node_at_cursor:parent()
    local next_node = nil
    if parent then
      local named_count = parent:named_child_count()
      for i = 0, named_count - 2 do
        if parent:named_child(i) == node_at_cursor then
          next_node = parent:named_child(i + 1)
          break
        end
      end
    end
    if next_node and next_node:type() == "link_destination" then
      return vim.split(node_text(next_node), "\n")[1]
    elseif next_node and next_node:type() == "link_label" then
      local link_label = vim.split(node_text(next_node), "\n")[1]
      return get_reference_link_destination(link_label)
    end
  elseif node_at_cursor:type() == "link_reference_definition" or node_at_cursor:type() == "inline_link" then
    local child_nodes = {}
    for i = 0, node_at_cursor:named_child_count() - 1 do
      table.insert(child_nodes, node_at_cursor:named_child(i))
    end
    for _, node in pairs(child_nodes) do
      if node:type() == "link_destination" then
        return vim.split(node_text(node), "\n")[1]
      end
    end
  elseif node_at_cursor:type() == "full_reference_link" then
    local child_nodes = {}
    for i = 0, node_at_cursor:named_child_count() - 1 do
      table.insert(child_nodes, node_at_cursor:named_child(i))
    end
    for _, node in pairs(child_nodes) do
      if node:type() == "link_label" then
        local link_label = vim.split(node_text(node), "\n")[1]
        return get_reference_link_destination(link_label)
      end
    end
  elseif node_at_cursor:type() == "link_label" then
    local link_label = vim.split(node_text(node_at_cursor), "\n")[1]
    return get_reference_link_destination(link_label)
  elseif node_at_cursor:type() == "uri_autolink" then
    local link_label = vim.split(node_text(node_at_cursor), "\n")[1]
    return string.gsub(link_label, "^<(.-)>$", "%1")
  else
    return
  end
end

local function resolve_link(link)
  local link_type

  if link:sub(1, 8) == [[https://]] or link:sub(1, 7) == [[http://]] then
    link_type = "web"
    return link, link_type
  elseif link:sub(1, 6) == [[man://]] then
    link_type = "man"
    return link, link_type
  elseif link:sub(1, 1) == [[#]] then
    link_type = "heading"
    return link:sub(2), link:sub(2)
  else
    link_type = "local"
    if link:sub(1, 1) == [[/]] then
      link = link
    elseif link:match("^%a:") then
      link = link
    elseif link:sub(1, 1) == [[~]] then
      link = os.getenv("HOME") .. [[/]] .. link:sub(2)
    else
      link = (fn.expand("%:p:h"):gsub("\\", "/")) .. [[/]] .. link
    end
    return link, link_type
  end
end

local function follow_local_link(link)
  local modified_link = nil
  -- Windows 盘符路径（C:/...）里的 : 不是行号分隔符，需特殊处理
  local path, line_number = link, nil
  if not link:match("^%a:[/\\]") then
    local path_and_line_number = vim.split(link, ":")
    path = path_and_line_number[1]
    line_number = path_and_line_number[2]
  end

  -- check if it is a directory, and create if true
  if path:sub(-1) == "/" then
    path = path:sub(1, -2)
    if vim.fn.glob(path) == "" then
      cmd(string.format("%s %s %s", "!mkdir", "-p", fn.fnameescape(path)))
    end
  end

  -- attempt to add an extension and open
  if path:sub(-3) ~= ".md" and vim.fn.glob(path) == "" then
    modified_link = path .. ".md"
  else
    modified_link = path
  end

  if modified_link then
    if line_number then
      vim.cmd("edit +" .. line_number .. " " .. modified_link)
    else
      vim.api.nvim_cmd({ cmd = "edit", args = { modified_link } }, {})
    end
  end
end

local function follow_heading_link(link)
  link = link:gsub("-", "[- ]*")
  link = link:gsub("_", "[_ ]*")
  vim.fn.search("\\c^#\\+ *" .. link, 'w')
end

local M = {}

function M.follow_link()
  local link_destination = get_link_destination()

  if link_destination then
    local resolved_link, link_type = resolve_link(link_destination)
    if link_type == "local" then
      local heading = resolved_link:match("#(.+)")
      resolved_link = resolved_link:match("^([^#]+)")
      follow_local_link(resolved_link)
      if heading then
        follow_heading_link(heading)
      end
    elseif link_type == "heading" then
      -- Save link position to jumplist
      cmd("normal! m'")
      follow_heading_link(resolved_link)
    elseif link_type == "man" then
      vim.cmd.Man(link_destination:gsub("man://", ""))
    elseif link_type == "web" then
      if is_linux then
        vim.system({ "xdg-open", resolved_link })
      elseif is_macos then
        vim.system({ "open", resolved_link })
      elseif is_windows then
        vim.system({ "cmd.exe", "/c", "start", "", resolved_link })
      end
    end
    return true
  end
  return false
end

-- 供 gf 映射使用：优先跟随 markdown 链接，找不到时回退内置 gf
function M.gf()
  if not M.follow_link() then
    vim.cmd("normal! gf")
  end
end

return M
