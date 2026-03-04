return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Open DiffView" },
    { "<leader>gD", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },
    { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close DiffView" },
  },
  opts = {},
}
