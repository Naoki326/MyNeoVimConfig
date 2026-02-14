return {
    "kdheepak/lazygit.nvim",
    cmd = "LazyGit",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
    },
    keys = {
        { "<leader>gg", ":LazyGit<CR>", noremap = true, silent = true }
    }
}
