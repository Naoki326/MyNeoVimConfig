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

        -- C# treesitter indent 兜底：返回 -1 时回退到 cindent
        _G._cs_ts_indent = function()
            local ts = require("nvim-treesitter").indentexpr()
            if ts >= 0 then return ts end
            return vim.fn.cindent(vim.v.lnum)
        end

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
                if vim.bo[args.buf].filetype == "cs" then
                    vim.bo[args.buf].indentexpr = "v:lua._cs_ts_indent()"
                else
                    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end
                -- fold: 代码折叠
                for _, winid in ipairs(vim.fn.win_findbuf(args.buf)) do
                    vim.wo[winid].foldexpr = "v:lua.vim.treesitter.foldexpr()"
                    vim.wo[winid].foldmethod = "expr"
                end
            end,
        })
    end,
}
