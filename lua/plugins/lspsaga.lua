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
        { "<leader>lr", ":Lspsaga rename<CR>", desc = "[C]ode [R]ename" },
        { "<leader>lc", ":Lspsaga code_action<CR>", desc = "[C]ode [A]ction" },
        { "<leader>ld", ":Lspsaga goto_definition<CR>", desc = "[G]oto [D]efinition" },
        { "<leader>lh", ":Lspsaga hover_doc<CR>", desc = "Hover Documentation" },
        { "<leader>lR", ":Lspsaga finder<CR>", desc = "[G]oto [R]eferences" },
        { "<leader>ln", ":Lspsaga diagnostic_jump_next<CR>", desc = "[G]oto [N]ext Diagnostic" },
        { "<leader>lp", ":Lspsaga diagnostic_jump_prev<CR>", desc = "[G]oto [P]reviours Diagnostic" },
    },
}
