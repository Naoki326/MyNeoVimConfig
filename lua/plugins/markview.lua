return {
    "OXY2DEV/markview.nvim",
    -- 文档明确要求：不要 lazy load，且要在 colorscheme 之后加载
    lazy = false,

    -- 依赖：markdown/markdown_inline treesitter parser（已在 treesitter.lua 安装）
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-tree/nvim-web-devicons",
    },

    opts = {
        preview = {
            -- 用 devicons（已装）而非内置 icon 提供器
            icon_provider = "devicons",
        },
        -- 关闭 anti-conceal：保持所有行都显示渲染结果，不隐藏原文
        anti_conceal = {
            enabled = false,
        },
    },
}
