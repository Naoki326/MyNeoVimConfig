return {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter.configs").setup({
            ensure_installed = {
                "c",
                "lua",
                "vim", "vimdoc",
                "query",
                "javascript",
                "python",
                "c_sharp",
                "markdown", "markdown_inline",
                "razor",
            },
            highlight = { enable = true },
            indent = { enable = true },
            fold = { enable = true },
        })
    end,
}
