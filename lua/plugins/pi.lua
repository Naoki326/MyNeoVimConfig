local pi_cmd = { "pi" }
local pi_continue_cmd = { "pi", "--continue" }

local terminal_opts = {
    win = {
        position = "float",
        width = 0.95,
        height = 0.95,
        border = "rounded",
        enter = true,
        title = " Pi ",
        title_pos = "center",
        on_buf = function(self)
            -- 记录 pi terminal 启动时的工作目录（= pi 进程的 cwd），
            -- send 时据此计算相对路径，避免受 nvim 后续 :lcd/:tcd 影响
            vim.b[self.buf].pi_cwd = vim.fn.getcwd()
        end,
    },
}

local function toggle_pi(cmd)
    require("snacks.terminal").toggle(cmd, vim.deepcopy(terminal_opts))
end

-- target 相对 base 的路径（优先 vim.fs.relpath，失败退化到相对当前 cwd）
local function relpath(base, target)
    local ok, rel = pcall(vim.fs.relpath, base, target)
    if ok and rel and rel ~= "" then
        return rel
    end
    return vim.fn.fnamemodify(target, ":.")
end

-- 当前 buffer 的绝对路径；非普通文件 buffer（terminal/nofile 等）返回空串
local function buf_abspath()
    if vim.bo.buftype ~= "" then
        return ""
    end
    return vim.fn.expand("%:p")
end

-- 确保 pi terminal 存在（必要时创建），返回 (term, pi_cwd)。
-- 注意：get/show 会把焦点切到 pi terminal，调用方必须在此之前捕获 buffer 信息。
local function get_pi()
    local snacks_term = require("snacks.terminal")
    local term = snacks_term.get(pi_cmd, vim.deepcopy(terminal_opts))
    if not term or not term.buf then
        return nil, nil
    end
    local pi_cwd = vim.b[term.buf].pi_cwd or vim.fn.getcwd()
    return term, pi_cwd
end

-- 把文本注入 pi terminal 的 TUI stdin（等效于在 pi 里打字），再显示 + 聚焦 +
-- 进入 insert。不自动回车，留给你补 prompt 后提交。
local function feed_pi(term, text)
    term:show()
    local job_id = vim.b[term.buf].terminal_job_id or vim.bo[term.buf].channel
    if not job_id or job_id == 0 then
        vim.notify("[pi] terminal 无 job channel", vim.log.levels.ERROR)
        return
    end
    vim.fn.chansend(job_id, text)
    term:focus()
    vim.cmd("startinsert")
end

return {
    "snacks.nvim",
    init = function()
        vim.api.nvim_create_user_command("Pi", function()
            toggle_pi(pi_cmd)
        end, { desc = "Toggle Pi in Snacks terminal" })

        vim.api.nvim_create_user_command("PiToggle", function()
            toggle_pi(pi_cmd)
        end, { desc = "Toggle Pi in Snacks terminal" })

        vim.api.nvim_create_user_command("PiContinue", function()
            toggle_pi(pi_continue_cmd)
        end, { desc = "Continue last Pi session in Snacks terminal" })
    end,
    keys = {
        { "<leader>p", "", desc = "+pi", mode = { "n", "v" } },
        {
            "<leader>pp",
            function()
                toggle_pi(pi_cmd)
            end,
            desc = "Toggle Pi",
            mode = { "n", "t" },
        },
        {
            "<leader>pc",
            function()
                toggle_pi(pi_continue_cmd)
            end,
            desc = "Continue last Pi session",
            mode = { "n", "t" },
        },
        {
            "<leader>pb",
            function()
                -- 先捕获当前文件路径（必须在 get_pi/show 切走焦点之前）
                local abs = buf_abspath()
                if abs == "" then
                    vim.notify("[pi] 当前 buffer 不是可发送的文件", vim.log.levels.WARN)
                    return
                end
                local term, cwd = get_pi()
                if not term then
                    vim.notify("[pi] terminal 不可用", vim.log.levels.ERROR)
                    return
                end
                -- @ 引用整个文件，pi 会把文件内容加载进上下文
                feed_pi(term, "@" .. relpath(cwd, abs) .. " ")
            end,
            desc = "Send buffer to Pi",
            mode = "n",
        },
        {
            "<leader>ps",
            function()
                -- 先捕获当前文件路径与选区行号（必须在 get_pi/show 切走焦点之前）
                local abs = buf_abspath()
                local s_line = vim.fn.line("'<")
                local e_line = vim.fn.line("'>")
                if abs == "" then
                    vim.notify("[pi] 当前 buffer 不是可发送的文件", vim.log.levels.WARN)
                    return
                end
                local term, cwd = get_pi()
                if not term then
                    vim.notify("[pi] terminal 不可用", vim.log.levels.ERROR)
                    return
                end
                local path = relpath(cwd, abs)
                -- 单行 文件:行，多行 文件:起-止
                local ref = (s_line == e_line)
                    and (path .. ":" .. s_line)
                    or (path .. ":" .. s_line .. "-" .. e_line)
                feed_pi(term, ref .. " ")
            end,
            desc = "Send selection range to Pi",
            mode = "v",
        },
    },
}
