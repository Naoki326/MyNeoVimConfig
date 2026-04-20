return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter").install({
            "c",
            "lua",
            "vim",
            "vimdoc",
            "query",
            "javascript",
            "python",
            "c_sharp",
            "markdown",
            "razor",
        })

        vim.filetype.add({
            extension = {
                razor = "razor",
                cshtml = "razor",
            },
        })

        vim.api.nvim_create_autocmd("FileType", {
            pattern = {
                "c",
                "lua",
                "vim",
                "help",
                "query",
                "javascript",
                "python",
                "cs",
                "markdown",
                "razor",
            },
            callback = function(args)
                vim.treesitter.start()
                vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
                vim.wo[0][0].foldmethod = "expr"
            end,
        })
    end,
}
