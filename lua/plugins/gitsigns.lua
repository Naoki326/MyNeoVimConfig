return {
  "lewis6991/gitsigns.nvim",
  event = "VeryLazy",
  opts = {
    signs = {
      add = { text = "+" },
      change = { text = "~" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "~" },
      untracked = { text = "?" },
    },
    signs_staged = {
      add = { text = "+" },
      change = { text = "~" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "~" },
    },
  },
  keys = {
    { "]h", function() require("gitsigns").nav_hunk("next") end, desc = "Next Hunk" },
    { "[h", function() require("gitsigns").nav_hunk("prev") end, desc = "Prev Hunk" },
    { "<leader>gp", function() require("gitsigns").preview_hunk() end, desc = "Preview Hunk" },
    { "<leader>gb", function() require("gitsigns").toggle_current_line_blame() end, desc = "Toggle Line Blame" },
    { "<leader>ghr", function() require("gitsigns").reset_hunk() end, desc = "Reset Hunk" },
    { "<leader>ghs", function() require("gitsigns").stage_hunk() end, desc = "Stage Hunk" },
    { "<leader>ghu", function() require("gitsigns").undo_stage_hunk() end, desc = "Undo Stage Hunk" },
  },
}
