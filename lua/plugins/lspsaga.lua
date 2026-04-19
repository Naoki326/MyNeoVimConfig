return {
    "nvimdev/lspsaga.nvim",
    cmd = "Lspsaga",
    opts = {
        finder = {
            keys = {
                toggle_or_open = "<CR>",
            },
        },
    },
    keys = {
        -- diagnostic jump（唯一不与其他插件重复的功能）
        { "<leader>cn", ":Lspsaga diagnostic_jump_next<CR>", desc = "[N]ext Diagnostic" },
        { "<leader>cp", ":Lspsaga diagnostic_jump_prev<CR>", desc = "[P]revious Diagnostic" },
    },
}
