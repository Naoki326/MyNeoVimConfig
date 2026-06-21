--- Claude Code 通知的自动部署（策略 A：全自动 + 备份）
-- 1. 同步 ~/.claude/hooks/on-stop.sh（我们自己的文件，幂等覆盖无风险）
-- 2. 合并 ~/.claude/settings.json 的 Stop hook（已注册则不动；改动时备份 .bak）
-- 由 plugins/claudecode.lua 的 init 在 VimEnter 时调 M.boot()，每次启动幂等自检。
local M = {}

--- hook 脚本内容（与 ~/.claude/hooks/on-stop.sh 保持一致；[=[ 避免脚本里 ]] 提前终止）
local HOOK_SCRIPT = [=[
#!/bin/bash
# Stop hook：每次 Claude 完成响应时触发
# 1. 设置标记，供 ccstatusline 检测后刷新缓存（原逻辑）
# 2. 通过 $NVIM 反向 RPC 通知父 Neovim（仅在 Neovim 终端内运行 Claude 时），
#    带上 session_id，供 Neovim 侧查找会话标题一并展示
touch "$HOME/.claude/statusline-stop.flag"

# 从 stdin 读 hook payload，提取 session_id（UUID，仅 [0-9a-f-]，可安全作为命令参数）
INPUT=$(cat 2>/dev/null || true)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
# jq 不在 PATH 时退回 sed（避免静默失败）
if [ -z "$SESSION_ID" ] && [ -n "$INPUT" ]; then
    SESSION_ID=$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
fi

# Neovim 在 :terminal 子进程中注入 $NVIM；从外部终端运行 Claude 时该变量为空
if [ -n "$NVIM" ]; then
    # remote-expr + execute：纯 RPC eval，不依赖 UI 事件循环；session_id 作为命令参数传入
    if [ -n "$SESSION_ID" ]; then
        nvim --server "$NVIM" --remote-expr "execute(\"ClaudeCodeNotify $SESSION_ID\")" >/dev/null 2>&1
    else
        nvim --server "$NVIM" --remote-expr 'execute("ClaudeCodeNotify")' >/dev/null 2>&1
    fi
fi

exit 0
]=]

local HOOK_COMMAND = "bash ~/.claude/hooks/on-stop.sh"
local HOOK_MARKER = "on-stop.sh" -- settings.json 的 command 含此字串视为已注册

local function read_file(path)
    local f = io.open(path, "r")
    if not f then
        return nil
    end
    local s = f:read("*a")
    f:close()
    return s
end

local function write_file(path, content)
    local f = io.open(path, "w")
    if not f then
        return false
    end
    f:write(content)
    f:close()
    return true
end

--- 用 jq 格式化 JSON；jq 不可用则返回紧凑原文（功能正常，仅不美观）
local function format_json(json_str)
    local out = vim.fn.system({ "jq", "." }, json_str)
    if vim.v.shell_error == 0 and type(out) == "string" and out ~= "" then
        return out
    end
    return json_str
end

--- settings.json 里 Stop hook 是否已注册
local function settings_has_hook(cfg)
    local stop = cfg and cfg.hooks and cfg.hooks.Stop
    if type(stop) ~= "table" then
        return false
    end
    for _, entry in ipairs(stop) do
        local hooks = entry and entry.hooks
        if type(hooks) == "table" then
            for _, h in ipairs(hooks) do
                if type(h) == "table" and type(h.command) == "string" and h.command:find(HOOK_MARKER, 1, true) then
                    return true
                end
            end
        end
    end
    return false
end

--- 同步 hook 脚本（幂等）
---@return "wrote"|"unchanged"|"error" wrote=本次写入 unchanged=已是最新 error=写入失败
local function sync_hook_script()
    local target = vim.fn.expand("~/.claude/hooks/on-stop.sh")
    local dir = vim.fn.fnamemodify(target, ":h")
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
    end
    if read_file(target) == HOOK_SCRIPT then
        return "unchanged"
    end
    return write_file(target, HOOK_SCRIPT) and "wrote" or "error"
end

--- 合并 settings.json 注册 Stop hook（幂等；改动时备份 .bak）
---@return "wrote"|"unchanged"|"error" wrote=本次改了 unchanged=已注册 error=写入失败
local function sync_settings()
    local path = vim.fn.expand("~/.claude/settings.json")
    local raw = read_file(path) or ""
    local cfg = {}
    if raw ~= "" then
        local ok, parsed = pcall(vim.json.decode, raw)
        if ok and type(parsed) == "table" then
            cfg = parsed
        end
    end
    if settings_has_hook(cfg) then
        return "unchanged"
    end
    if raw ~= "" then
        write_file(path .. ".bak", raw)
    end
    cfg.hooks = cfg.hooks or {}
    cfg.hooks.Stop = cfg.hooks.Stop or {}
    table.insert(cfg.hooks.Stop, { hooks = { { type = "command", command = HOOK_COMMAND } } })
    return write_file(path, format_json(vim.json.encode(cfg))) and "wrote" or "error"
end

--- 检查硬依赖；返回缺失项列表（空表=就绪）
--- 只检 Neovim 版本：bash/jq 都是 hook 执行侧（Claude Code）的依赖，不由 neovim 预检——
--- CC 拿不到 bash 整个 hook 就跑不起来（功能直接罢工），jq 缺失 hook 脚本有 sed 兜底。
function M.check_deps()
    local missing = {}
    local v = vim.version()
    if v.major == 0 and v.minor < 9 then
        table.insert(missing, "Neovim ≥ 0.9（当前 " .. tostring(v) .. "；$NVIM 自动注入与 vim.on_key 需要）")
    end
    return missing
end

--- 启动自检：硬依赖缺失才阻断；否则同步脚本 + 合并 settings（幂等；有变更/失败才通知）
function M.boot()
    local missing = M.check_deps()
    if #missing > 0 then
        -- 硬依赖缺失（如 Neovim 版本不足）：功能无法工作，不部署
        vim.schedule(function()
            vim.notify("CC Notify 硬依赖缺失，对话完成通知将不生效：\n  • " .. table.concat(missing, "\n  • "),
                vim.log.levels.ERROR)
        end)
        return
    end
    local s_script = sync_hook_script()
    local s_settings = sync_settings()
    vim.schedule(function()
        -- 写入失败优先报错，避免"静默失败"被当成"已是最新"
        local errors = {}
        if s_script == "error" then
            table.insert(errors, "on-stop.sh")
        end
        if s_settings == "error" then
            table.insert(errors, "settings.json")
        end
        if #errors > 0 then
            vim.notify("CC Notify 写入失败（权限/磁盘？），请检查：" .. table.concat(errors, " + "),
                vim.log.levels.ERROR)
            return
        end
        local wrote = {}
        if s_script == "wrote" then
            table.insert(wrote, "on-stop.sh")
        end
        if s_settings == "wrote" then
            table.insert(wrote, "settings.json(.bak 已备份)")
        end
        if #wrote > 0 then
            vim.notify("CC Notify: 已自动部署 " .. table.concat(wrote, " + "), vim.log.levels.INFO)
        end
    end)
end

--- 手动重新部署（供 :CCNotifyInstall，强制跑一遍并通知结果）
function M.install()
    local missing = M.check_deps()
    if #missing > 0 then
        vim.notify("CC Notify 硬依赖缺失，无法部署：\n  • " .. table.concat(missing, "\n  • "), vim.log.levels.ERROR)
        return
    end
    local s_script = sync_hook_script()
    local s_settings = sync_settings()
    local errors = {}
    if s_script == "error" then
        table.insert(errors, "on-stop.sh")
    end
    if s_settings == "error" then
        table.insert(errors, "settings.json")
    end
    if #errors > 0 then
        vim.notify("CC Notify 写入失败（权限/磁盘？）：" .. table.concat(errors, " + "), vim.log.levels.ERROR)
        return
    end
    local msg = (s_script == "wrote" or s_settings == "wrote") and "部署/更新完成" or "已是最新，无需变更"
    vim.notify("CC Notify: " .. msg, vim.log.levels.INFO)
end

--- 供测试/外部查询：当前是否已就位
function M.is_deployed()
    local target = vim.fn.expand("~/.claude/hooks/on-stop.sh")
    if read_file(target) ~= HOOK_SCRIPT then
        return false
    end
    local raw = read_file(vim.fn.expand("~/.claude/settings.json")) or ""
    local ok, cfg = pcall(vim.json.decode, raw)
    return ok and settings_has_hook(cfg)
end

return M
