return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter").setup()

        -- Windows 上 uv_symlink 需要管理员权限，install() 无法创建 site/queries 的符号链接
        -- 直接把 nvim-treesitter 的 runtime/ 目录加入 runtimepath，让 Neovim 能搜到 queries
        if vim.fn.has("win32") == 1 then
            local runtime_dir = require("nvim-treesitter.install").get_package_path("runtime")
            vim.opt.rtp:prepend(runtime_dir)
        end

        -- 异步安装常用 parser（已安装则跳过）
        require("nvim-treesitter").install {
            "c",
            "lua",
            "vim",
            "vimdoc",
            "query",
            "javascript",
            "python",
            "c_sharp",
            "markdown",
            "markdown_inline",
        }

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
                -- indent: 缩进（experimental）
                vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                -- fold: 代码折叠
                vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
                vim.wo[0][0].foldmethod = "expr"
            end,
        })
    end,
}
