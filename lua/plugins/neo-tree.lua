return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
    "s1n7ax/nvim-window-picker",
  },
  keys = {
    { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle Neo-tree" },
    { "<leader>o", "<cmd>Neotree focus<cr>", desc = "Focus Neo-tree" },
  },
  config = function()
    require("neo-tree").setup({
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
        follow_current_file = {
          enabled = true,
        },
        use_libuv_file_watcher = true,
      },
      window = {
        position = "left",
        width = 30,
      },
      default_component_configs = {
        indent = {
          with_expanders = true,
          expander_collapsed = "",
          expander_expanded = "",
        },
      },

      renderers = {
        file = {
          { "indent" },
          { "icon" },
          {
            "container",
            content = {
              { "name",           zindex = 10 },
              { "symlink_target", zindex = 10, highlight = "NeoTreeSymbolicLinkTarget" },
              { "clipboard",      zindex = 10 },
              { "bufnr",          zindex = 10 },
              { "modified",       zindex = 20, align = "right" },
              { "diagnostics",    zindex = 20, align = "right" },
              { "git_status",     zindex = 10, align = "right" },
            },
          },
        },
      },
    })
  end,
}
