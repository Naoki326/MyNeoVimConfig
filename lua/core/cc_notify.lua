--- Claude Code 对话完成通知
-- 由 ~/.claude/hooks/on-stop.sh 通过 $NVIM 反向 RPC 触发：
--   nvim --server "$NVIM" --remote-expr 'execute("ClaudeCodeNotify <session-id>")'
-- 通知渲染由 snacks.notifier 接管（noice 的通知已禁用，见 plugins/noice.lua）。
--
-- 行为：对话完成时持久显示（timeout=0），检测到任意按键后 10 秒自动关闭。
local M = {}

local NOTIFY_ID = "cc-stop-notify"
local DISMISS_MS = 10000 -- 检测到按键后多少毫秒关闭

---@class cc_notify.state
---@field armed boolean 是否正在等待首次按键
---@field key_detach fun()?|nil vim.on_key 返回的 detach 函数
---@field close_timer table|nil 关闭倒计时 timer
M._state = { armed = false, key_detach = nil, close_timer = nil }

--- 清理关闭 timer
local function clear_timer()
    local t = M._state.close_timer
    if t then
        if not t:is_closing() then
            t:stop()
            t:close()
        end
        M._state.close_timer = nil
    end
end

--- 注销按键监听
local function detach_key()
    if M._state.key_detach then
        pcall(M._state.key_detach)
        M._state.key_detach = nil
    end
end

--- 关闭通知并清理所有监听
local function dismiss()
    detach_key()
    clear_timer()
    ---@diagnostic disable-next-line: undefined-global
    pcall(function()
        Snacks.notifier.hide(NOTIFY_ID)
    end)
end

--- 立即关闭通知并清理监听（倒计时到期时调用，也可手动调用）
M.dismiss = dismiss

--- 启动关闭倒计时（首次按键后调用）
local function start_countdown()
    clear_timer()
    local timer = vim.uv.new_timer()
    M._state.close_timer = timer
    timer:start(DISMISS_MS, 0, function()
        vim.schedule(dismiss)
    end)
end

--- 武装按键监听：注册 on_key，收到首次按键后启动倒计时
local function arm()
    detach_key()
    clear_timer()
    M._state.armed = true
    M._state.key_detach = vim.on_key(function()
        -- 用 armed 标志位保证只在首次按键时启动倒计时，不在回调内 detach 自身
        if not M._state.armed then
            return
        end
        M._state.armed = false
        start_countdown()
    end)
end

--- 清理标题文本：去换行/控制字符、压空白、截断长度
---@param s any
---@return string|nil
local function clean(s)
    if not s or s == "" then
        return nil
    end
    s = tostring(s)
    s = s:gsub("[\r\n\t]+", " "):gsub("%c", ""):gsub("^%s+", ""):gsub("%s+$", "")
    s = s:gsub("%s+", " ")
    if #s > 60 then
        s = s:sub(1, 60) .. "…"
    end
    if s == "" then
        return nil
    end
    return s
end

--- 从 transcript 行对象提取 user 消息的文本（content 可能是 string 或 [{type=text,text=...}]）
---@param obj table
---@return string|nil
local function extract_user_text(obj)
    local content = (obj.message and obj.message.content) or obj.content
    if type(content) == "string" then
        return content
    end
    if type(content) == "table" then
        for _, block in ipairs(content) do
            if type(block) == "table" and block.type == "text" and block.text then
                return block.text
            end
        end
    end
    return nil
end

--- 从 sessions-index.json 查（已完成会话；当前活跃会话不在其中）
---@param session_id string
---@return string|nil
local function from_sessions_index(session_id)
    local idx_files = vim.fn.glob(vim.fn.expand("~/.claude/projects") .. "/*/sessions-index.json", false, true)
    if type(idx_files) == "string" then
        idx_files = idx_files == "" and {} or { idx_files }
    end
    for _, f in ipairs(idx_files) do
        local ok, lines = pcall(vim.fn.readfile, f)
        if ok and lines and #lines > 0 then
            local jok, parsed = pcall(vim.json.decode, table.concat(lines, "\n"))
            if jok and parsed and parsed.entries then
                for _, e in ipairs(parsed.entries) do
                    if e.sessionId == session_id then
                        -- 优先 summary；占位符/空值时退回 firstPrompt（用户首句）
                        local t = e.summary
                        if not t or t == "" or t == "New Conversation" then
                            t = e.firstPrompt
                        end
                        return clean(t)
                    end
                end
            end
        end
    end
    return nil
end

--- 直接读 transcript JSONL：优先 summary 行，否则第一条 user 消息文本
--- 当前活跃会话不在 sessions-index.json，但 transcript 文件已存在
---@param session_id string
---@return string|nil
local function from_transcript(session_id)
    local files = vim.fn.glob(vim.fn.expand("~/.claude/projects") .. "/*/" .. session_id .. ".jsonl", false, true)
    if type(files) == "string" then
        files = files == "" and {} or { files }
    end
    for _, f in ipairs(files) do
        local ok, lines = pcall(vim.fn.readfile, f)
        if ok and lines then
            local first_user
            for _, line in ipairs(lines) do
                local jok, obj = pcall(vim.json.decode, line)
                if jok and type(obj) == "table" then
                    if obj.type == "summary" and obj.summary and obj.summary ~= "" then
                        return clean(obj.summary)
                    end
                    if not first_user and obj.type == "user" then
                        first_user = extract_user_text(obj)
                    end
                end
            end
            if first_user then
                return clean(first_user)
            end
        end
    end
    return nil
end

--- 查会话标题：先 sessions-index.json（已完成），再 transcript（进行中）
---@param session_id string
---@return string|nil
function M._resolve_title(session_id)
    if not session_id or session_id == "" then
        return nil
    end
    return from_sessions_index(session_id) or from_transcript(session_id)
end

--- 每次 Claude 响应结束时由 Stop hook 触发
--- 持久显示通知；若上一条还在（含倒计时中），刷新内容并重新等待按键
---@param session_id? string 当前会话 ID，用于查找标题
function M.on_stop(session_id)
    local title = M._resolve_title(session_id)
    local msg = title and ("对话已完成 — " .. title) or "对话已完成 — 等待你的下一步指令"
    local ok = pcall(function()
        ---@diagnostic disable-next-line: undefined-global
        return Snacks
    end)
    ---@diagnostic disable-next-line: undefined-global
    if ok and Snacks and Snacks.notify then
        -- timeout=0：持久显示，直到 dismiss() 手动 hide
        Snacks.notify(msg, {
            id = NOTIFY_ID,
            title = "✅ Claude Code",
            level = "info",
            icon = "🤖",
            timeout = 0,
        })
        arm() -- 武装按键监听（同时清理上一次的倒计时）
    else
        vim.notify("✅ " .. msg, vim.log.levels.INFO, { title = "Claude Code" })
    end
end

return M
