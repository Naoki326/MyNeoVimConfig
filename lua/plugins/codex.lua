local codex_cmd = { "codex", "--yolo" }
local codex_resume_cmd = { "codex", "--yolo", "resume", "--last" }

local terminal_opts = {
    win = {
        position = "float",
        width = 0.95,
        height = 0.95,
        border = "rounded",
        enter = true,
        title = " Codex ",
        title_pos = "center",
    },
}

local function toggle_codex(cmd)
    require("snacks.terminal").toggle(cmd, vim.deepcopy(terminal_opts))
end

return {
    "snacks.nvim",
    init = function()
        vim.api.nvim_create_user_command("Codex", function()
            toggle_codex(codex_cmd)
        end, { desc = "Toggle Codex in Snacks terminal" })

        vim.api.nvim_create_user_command("CodexToggle", function()
            toggle_codex(codex_cmd)
        end, { desc = "Toggle Codex in Snacks terminal" })

        vim.api.nvim_create_user_command("CodexResume", function()
            toggle_codex(codex_resume_cmd)
        end, { desc = "Resume last Codex session in Snacks terminal" })
    end,
    keys = {
        {
            "<leader>cc",
            function()
                toggle_codex(codex_cmd)
            end,
            desc = "Toggle Codex",
            mode = { "n", "t" },
        },
        {
            "<leader>cr",
            function()
                toggle_codex(codex_resume_cmd)
            end,
            desc = "Resume last Codex session",
            mode = { "n", "t" },
        },
    },
}
