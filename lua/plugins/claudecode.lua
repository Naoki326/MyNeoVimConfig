return {
    "coder/claudecode.nvim",
    init = function()
        -- 对话完成通知入口：由 ~/.claude/hooks/on-stop.sh 通过
        -- `nvim --server $NVIM --remote-expr 'execute("ClaudeCodeNotify <session-id>")'` 触发。
        -- 用 remote-expr 而非 remote-send：纯 RPC eval，不依赖 UI 事件循环，
        -- headless 与正常实例都可靠执行。可选 session_id 参数用于查找会话标题。
        vim.api.nvim_create_user_command("ClaudeCodeNotify", function(opts)
            require("core.cc_notify").on_stop(opts.fargs[1])
        end, { desc = "Claude Code 对话完成通知（Stop hook 触发）", nargs = "?" })

        -- 手动部署/更新（一般无需调用：VimEnter 已自动跑）
        vim.api.nvim_create_user_command("CCNotifyInstall", function()
            require("core.cc_notify_setup").install()
        end, { desc = "部署/更新 Claude 通知的 hook 与 settings.json" })

        -- 策略 A：VimEnter 时自动幂等自检部署（同步 hook 脚本 + 合并 settings.json）
        local grp = vim.api.nvim_create_augroup("cc_notify_setup", { clear = true })
        vim.api.nvim_create_autocmd("VimEnter", {
            once = true,
            group = grp,
            callback = function()
                pcall(function()
                    require("core.cc_notify_setup").boot()
                end)
            end,
            desc = "自动部署 Claude 对话完成通知（hook 脚本 + settings.json）",
        })
    end,
    opts = {
        terminal_cmd = "claude --dangerously-skip-permissions",
        terminal = {
            provider = "snacks",
            snacks_win_opts = {
                position = "float",
                width = 0.95,
                height = 0.95,
                border = "rounded",
            },
        },
    },
    keys = {
        { "<leader>a",  "",                               desc = "+ai",               mode = { "n", "v" } },
        { "<leader>ac", "<cmd>ClaudeCode<cr>",            desc = "Toggle Claude" },
        { "<leader>af", "<cmd>ClaudeCodeFocus<cr>",       desc = "Focus Claude" },
        { "<leader>ar", "<cmd>ClaudeCode --resume<cr>",   desc = "Resume Claude" },
        { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
        { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",       desc = "Add current buffer" },
        { "<leader>as", "<cmd>ClaudeCodeSend<cr>",        mode = "v",                 desc = "Send to Claude" },
        {
            "<leader>as",
            "<cmd>ClaudeCodeTreeAdd<cr>",
            desc = "Add file",
            ft = { "NvimTree", "neo-tree", "oil" },
        },
        -- Diff management
        { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
        { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",   desc = "Deny diff" },
    },
}
