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

local function buf_abspath()
    return vim.fn.expand("%:p")
end

-- 确保 pi terminal 可见、拿到 job channel 与启动 cwd，用 build_text(pi_cwd)
-- 构造文本后 chansend 到 pi 的 TUI stdin（等效于在 pi 里打字），再聚焦终端进入
-- insert。不自动回车，留给你补 prompt 后提交。build_text 返回 nil 则不发送。
local function send_to_pi(build_text)
    local snacks_term = require("snacks.terminal")
    local term = snacks_term.get(pi_cmd, vim.deepcopy(terminal_opts))
    if not term or not term.buf then
        vim.notify("[pi] terminal 不可用", vim.log.levels.ERROR)
        return
    end
    term:show()
    local job_id = vim.b[term.buf].terminal_job_id or vim.bo[term.buf].channel
    if not job_id or job_id == 0 then
        vim.notify("[pi] terminal 无 job channel", vim.log.levels.ERROR)
        return
    end
    local pi_cwd = vim.b[term.buf].pi_cwd or vim.fn.getcwd()
    local text = build_text(pi_cwd)
    if not text then
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
                send_to_pi(function(cwd)
                    local abs = buf_abspath()
                    if abs == "" then
                        vim.notify("[pi] 当前 buffer 无文件路径", vim.log.levels.WARN)
                        return nil
                    end
                    -- @ 引用整个文件，pi 会把文件内容加载进上下文
                    return "@" .. relpath(cwd, abs) .. " "
                end)
            end,
            desc = "Send buffer to Pi",
            mode = "n",
        },
        {
            "<leader>ps",
            function()
                send_to_pi(function(cwd)
                    local abs = buf_abspath()
                    if abs == "" then
                        vim.notify("[pi] 当前 buffer 无文件路径", vim.log.levels.WARN)
                        return nil
                    end
                    local path = relpath(cwd, abs)
                    local s_line = vim.fn.line("'<")
                    local e_line = vim.fn.line("'>")
                    -- 单行 文件:行，多行 文件:起-止
                    local ref = (s_line == e_line)
                        and (path .. ":" .. s_line)
                        or (path .. ":" .. s_line .. "-" .. e_line)
                    return ref .. " "
                end)
            end,
            desc = "Send selection range to Pi",
            mode = "v",
        },
    },
}
