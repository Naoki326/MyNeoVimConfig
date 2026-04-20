-- 只保留 cmdline 美化和 LSP hover/signature 文档美化
-- 通知由 snacks.notifier 接管，不启用 noice 的消息路由
return {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
        "MunifTanjim/nui.nvim",
    },
    init = function()
        -- cmdline_popup 用浮动窗口接管命令行，隐藏原生命令行区域避免底部空行
        vim.opt.cmdheight = 0
    end,
    opts = {
        -- 禁用 noice 的通知功能（snacks.notifier 已接管）
        notify = {
            enabled = false,
        },
        -- 禁用消息路由（snacks.notifier 已接管）
        messages = {
            enabled = false,
        },
        -- LSP 文档美化（hover, signature, 文档弹窗）
        lsp = {
            override = {
                ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                ["vim.lsp.util.stylize_markdown"] = true,
                ["cmp.entry.get_documentation"] = true,
            },
            hover = { enabled = true },
            signature = { enabled = true },
            progress = { enabled = false }, -- snacks notifier 已处理 LSP 进度
            message = { enabled = false },
            documentation = { enabled = true },
        },
        -- cmdline 美化
        cmdline = {
            enabled = true,
            view = "cmdline_popup", -- 浮动窗口
            opts = {},
            format = {
                cmdline = { pattern = "^:", icon = "", lang = "vim" },
                search_down = { kind = "search", pattern = "^/", icon = " ", lang = "regex" },
                search_up = { kind = "search", pattern = "^%?", icon = " ", lang = "regex" },
                filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
                lua = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = "", lang = "lua" },
                help = { pattern = "^:%s*he?l?p?%s+", icon = "󰋖" },
                input = {}, -- 空格式用于 vim.ui.input 等
            },
        },
        -- 禁用 noice 的消息历史记录（snacks.notifier 已接管）
        routes = {},
        presets = {
            bottom_search = true, -- 搜索保持在底部
            command_palette = true, -- 命令行补全用 VS Code 式面板
            long_message_to_split = false,
            inc_rename = false,
            lsp_doc_border = true, -- LSP 文档弹窗带边框
        },
    },
    -- stylua: ignore
    keys = {
        { "<S-Enter>", function() require("noice").redirect(vim.fn.getcmdline()) end,                 mode = "c",    desc = "Redirect Cmdline" },
        { "<c-f>",     function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end,  silent = true, expr = true,              desc = "Scroll Forward",  mode = { "i", "n", "s" } },
        { "<c-b>",     function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, silent = true, expr = true,              desc = "Scroll Backward", mode = { "i", "n", "s" } },
    },
    config = function(_, opts)
        if vim.o.filetype == "lazy" then
            vim.cmd([[messages clear]])
        end
        require("noice").setup(opts)
    end,
}
