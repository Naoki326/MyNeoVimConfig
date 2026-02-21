---解析 .sln / .csproj 文件，判断 .cs 文件是否被解决方案编译
local M = {}

M._initialized = false
M._projects = {} -- {dir, sdk, includes[], excludes[]}
M._file_cache = {} -- normalized path -> bool

local has_win32 = vim.fn.has("win32") == 1

local function normalize(path)
  if not path then return nil end
  local abs = vim.fn.fnamemodify(path, ":p")
  abs = abs:gsub("\\", "/"):gsub("/$", "")
  if has_win32 then abs = abs:lower() end
  return abs
end

local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*all")
  f:close()
  return content
end

-- 将单个路径分量的 glob 模式转为 Lua 正则（不含 **）
local function part_to_pattern(part)
  local p = part
    :gsub("([%.%(%)%+%[%]%^%$%%{}|])", "%%%1") -- 转义 Lua 特殊字符
    :gsub("%*", "[^/]*") -- * 匹配任意非分隔符字符
    :gsub("%?", "[^/]") -- ? 匹配单个非分隔符字符
  return "^" .. p .. "$"
end

-- 按 / 分割路径为分量列表
local function split_parts(path)
  local parts = {}
  for part in path:gmatch("[^/]+") do
    table.insert(parts, part)
  end
  return parts
end

-- 递归 glob 匹配（正确处理 **）
local function glob_match(path_parts, pi, pat_parts, gi)
  if gi > #pat_parts then
    return pi > #path_parts
  end
  -- 路径已耗尽，剩余 pattern 必须全为 **
  if pi > #path_parts then
    for i = gi, #pat_parts do
      if pat_parts[i] ~= "**" then return false end
    end
    return true
  end

  local gp = pat_parts[gi]
  if gp == "**" then
    -- ** 匹配零个或多个路径分量
    for skip = 0, #path_parts - pi + 1 do
      if glob_match(path_parts, pi + skip, pat_parts, gi + 1) then
        return true
      end
    end
    return false
  end

  -- 单分量匹配
  local pp = pat_parts[pi]
  if has_win32 then pp = pp:lower() end
  local ok, res = pcall(function()
    return pp:match(part_to_pattern(gp)) ~= nil
  end)
  if not (ok and res) then return false end
  return glob_match(path_parts, pi + 1, pat_parts, gi + 1)
end

local function matches_glob(rel_path, glob_pattern)
  -- rel_path 不应含前导 /，但作防御处理
  local rel = rel_path:gsub("^/+", "")
  local pat = glob_pattern:gsub("\\", "/")
  if has_win32 then
    rel = rel:lower()
    pat = pat:lower()
  end
  local path_parts = split_parts(rel)
  local pat_parts = split_parts(pat)
  if #path_parts == 0 or #pat_parts == 0 then return false end
  local ok, res = pcall(glob_match, path_parts, 1, pat_parts, 1)
  return ok and (res == true)
end

local function is_sdk_style(content)
  return content:match("<Project%s+Sdk=") ~= nil
end

local function parse_csproj(csproj_path)
  local content = read_file(csproj_path)
  if not content then return nil end

  local dir = normalize(vim.fn.fnamemodify(csproj_path, ":h"))
  local sdk = is_sdk_style(content)
  local includes = {}
  local excludes = {}

  if sdk then
    excludes = { "obj/**", "bin/**", "**/*.user" }
    for remove in content:gmatch('<Compile%s+Remove="([^"]*)"') do
      table.insert(excludes, (remove:gsub("\\", "/")))
    end
    for inc in content:gmatch('<Compile%s+Include="([^"]*)"') do
      table.insert(includes, normalize(dir .. "/" .. inc:gsub("\\", "/")))
    end
  else
    for inc in content:gmatch('<Compile%s+Include="([^"]*)"') do
      table.insert(includes, normalize(dir .. "/" .. inc:gsub("\\", "/")))
    end
  end

  return { dir = dir, sdk = sdk, includes = includes, excludes = excludes }
end

local function parse_sln(sln_path)
  local content = read_file(sln_path)
  if not content then return nil end

  local sln_dir = vim.fn.fnamemodify(sln_path, ":h"):gsub("\\", "/")
  local projects = {}

  for rel_path in content:gmatch('"([^"]*%.csproj)"') do
    rel_path = rel_path:gsub("\\", "/")
    local full_path = normalize(sln_dir .. "/" .. rel_path)
    local proj = parse_csproj(full_path)
    if proj then
      table.insert(projects, proj)
    end
  end

  return projects
end

---在 start_dir 及其父目录中查找 .sln 文件
function M.find_sln(start_dir)
  local dir = vim.fn.fnamemodify(start_dir or vim.fn.getcwd(), ":p")
  dir = dir:gsub("\\", "/"):gsub("/$", "")

  for _ = 1, 6 do
    local slns = vim.fn.glob(dir .. "/*.sln", false, true)
    if #slns > 0 then return slns[1] end
    local parent = vim.fn.fnamemodify(dir, ":h"):gsub("\\", "/"):gsub("/$", "")
    if parent == dir then break end
    dir = parent
  end
  return nil
end

---从 .sln 文件初始化
---@param sln_path string|nil  nil 则自动查找
---@return boolean
function M.init(sln_path)
  sln_path = sln_path or M.find_sln()
  if not sln_path then return false end

  local projects = parse_sln(sln_path)
  if not projects then return false end

  M._projects = projects
  M._file_cache = {}
  M._initialized = true
  return true
end

---判断 .cs 文件是否被解决方案编译
---@param file_path string
---@return boolean|nil  true=在解决方案中，false=不在，nil=非.cs文件或未初始化
function M.is_in_solution(file_path)
  if not file_path or not file_path:match("%.cs$") then return nil end
  if not M._initialized then return nil end

  local norm = normalize(file_path)
  if M._file_cache[norm] ~= nil then return M._file_cache[norm] end

  local result = false
  for _, proj in ipairs(M._projects) do
    if proj.sdk then
      local prefix = proj.dir .. "/"
      if norm:sub(1, #prefix) == prefix then
        -- 正确取相对路径：+1 跳过前导 /
        local rel = norm:sub(#prefix + 1)
        local excluded = false
        for _, pat in ipairs(proj.excludes) do
          if matches_glob(rel, pat) then
            excluded = true
            break
          end
        end
        if not excluded then
          result = true
          break
        end
      end
      -- 检查显式额外 Include
      if not result then
        for _, inc in ipairs(proj.includes) do
          if inc == norm then
            result = true
            break
          end
        end
      end
    else
      for _, inc in ipairs(proj.includes) do
        if inc == norm then
          result = true
          break
        end
      end
    end
    if result then break end
  end

  M._file_cache[norm] = result
  return result
end

return M
