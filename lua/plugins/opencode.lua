return {
  {
    "nickjvandyke/opencode.nvim",
    version = "*",
    dependencies = {
      {
        "folke/snacks.nvim",
        optional = true,
        opts = {
          input = {},
          picker = {
            actions = {
              opencode_send = function(...)
                return require("opencode").snacks_picker_send(...)
              end,
            },
            win = {
              input = {
                keys = {
                  ["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
                },
              },
            },
          },
        },
      },
    },
    config = function()
      ---@type snacks.terminal.Opts
      local snacks_terminal_opts = {
        win = {
          position = "float",
          width = 0.90,
          height = 0.90,
          border = "rounded",
          enter = true,
          on_win = function(win)
            -- require("opencode.terminal").setup(win.win)
            -- vim.schedule(function()
            --   vim.cmd("startinsert")
            -- end)
          end,
        },
      }

      local opencode_cmd = "opencode --port"

      ---@type opencode.Opts
      vim.g.opencode_opts = {
        server = {
          start = function()
            require("snacks.terminal").open(opencode_cmd, snacks_terminal_opts)
          end,
          stop = function()
            local term = require("snacks.terminal").get(opencode_cmd, snacks_terminal_opts)
            if term then
              term:close()
            end
          end,
          toggle = function()
            require("snacks.terminal").toggle(opencode_cmd, snacks_terminal_opts)
          end,
        },
      }

      vim.o.autoread = true

      vim.keymap.set({ "n", "x" }, "<leader>oo", function()
        require("opencode").ask("@this: ", { submit = false })
      end, { desc = "Ask opencode" })
      vim.keymap.set({ "n", "x" }, "<leader>ox", function()
        require("opencode").select()
      end, { desc = "Execute opencode action" })
      vim.keymap.set({ "n", "t" }, "<leader>og", function()
        require("opencode").toggle()
      end, { desc = "Toggle opencode" })
    end,
  },
}
