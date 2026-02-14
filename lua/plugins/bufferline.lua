return {
    "akinsho/bufferline.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons"
    },
    opts = {},
    keys = {
        { "<leader>bh", ":BufferLineCyclePrev<CR>", silent = true},
        { "<leader>bl", ":BufferLineCycleNext<CR>", silent = true},
        { "<leader>bp", ":BufferLinePick<CR>", silent = true},
        { "<leader>bd", ":bdelete<CR>", silent = true},
        { "<S-h>", ":BufferLineCyclePrev<CR>", silent = true},
        { "<S-l>", ":BufferLineCycleNext<CR>", silent = true},
        -- { "<S-p>", ":BufferLinePick<CR>", silent = true},
        -- { "<S-d>", ":bdelete<CR>", silent = true},
    },
    lazy = false,
}
