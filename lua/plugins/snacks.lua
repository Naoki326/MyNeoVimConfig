return {
  "snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    notifier = { enabled = true },
    picker = { enabled = true, ui_select = true },
    dashboard = {
      preset = {
        pick = function(cmd, opts)
          local map = { files = "files", live_grep = "grep", oldfiles = "recent" }
          local picker = map[cmd] or cmd
          return Snacks.picker[picker](opts)
        end,
        header = [[
        ██╗      █████╗ ███████╗██╗   ██╗██╗   ██╗██╗███╗   ███╗          Z
        ██║     ██╔══██╗╚══███╔╝╚██╗ ██╔╝██║   ██║██║████╗ ████║      Z
        ██║     ███████║  ███╔╝  ╚████╔╝ ██║   ██║██║██╔████╔██║   z
        ██║     ██╔══██║ ███╔╝    ╚██╔╝  ╚██╗ ██╔╝██║██║╚██╔╝██║ z
        ███████╗██║  ██║███████╗   ██║    ╚████╔╝ ██║██║ ╚═╝ ██║
        ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝     ╚═══╝  ╚═╝╚═╝     ╚═╝
 ]],
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          { icon = " ", key = "p", desc = "Projects", action = ":lua Snacks.picker.projects()" },
          { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
          { icon = " ", key = "s", desc = "Restore Session", section = "session" },
          { icon = " ", key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
          { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
      },
    },
  },
  keys = {
    -- buffers / files
    { "<leader>,", function() Snacks.picker.buffers({ sort = { "lastused", "bufnr" } }) end, desc = "Switch Buffer" },
    { "<leader><space>", function() Snacks.picker.files() end, desc = "Find Files (Root Dir)" },
    { "<leader>fb", function() Snacks.picker.buffers({ sort = { "lastused", "bufnr" } }) end, desc = "Buffers" },
    { "<leader>fB", function() Snacks.picker.buffers() end, desc = "Buffers (all)" },
    { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Files (git-files)" },
    { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent" },

    -- git
    { "<leader>gc", function() Snacks.picker.git_log() end, desc = "Commits" },
    { "<leader>gl", function() Snacks.picker.git_log() end, desc = "Commits" },
    { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Status" },
    { "<leader>gS", function() Snacks.picker.git_stash() end, desc = "Git Stash" },

    -- search / grep
    { '<leader>s"', function() Snacks.picker.registers() end, desc = "Registers" },
    { "<leader>s/", function() Snacks.picker.search_history() end, desc = "Search History" },
    { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Auto Commands" },
    { "<leader>sb", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
    { "<leader>sc", function() Snacks.picker.command_history() end, desc = "Command History" },
    { "<leader>sC", function() Snacks.picker.commands() end, desc = "Commands" },
    { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
    { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
    { "<leader>sG", function() Snacks.picker.grep({ glob = { "*.cs", "*.razor", "*.css" } }) end, desc = "Grep (Root Dir)" },
    { "<leader>sg", function() Snacks.picker.grep() end, desc = "Grep (cwd)" },
    { "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages" },
    { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Search Highlight Groups" },
    { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumplist" },
    { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Key Maps" },
    { "<leader>sl", function() Snacks.picker.loclist() end, desc = "Location List" },
    { "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages" },
    { "<leader>sm", function()
      local lines = vim.split(vim.fn.execute("messages"), "\n")
      lines = vim.tbl_filter(function(l) return l:match("%S") end, lines)
      local buf = vim.api.nvim_create_buf(false, true)
      vim.bo[buf].modifiable = true
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.bo[buf].modifiable = false
      vim.bo[buf].buftype = "nofile"
      vim.bo[buf].filetype = "lua"
      vim.api.nvim_buf_call(buf, function()
        vim.cmd([[
          syn match MsgError "\\c\\<error\\>\\|\\[ERROR\\]"
          syn match MsgWarn  "\\c\\<warn\\>\\|\\<warning\\>\\|\\[WARN\\]"
          syn match MsgInfo  "\\c\\<info\\>\\|\\[INFO\\]"
          syn match MsgSuccess "\\c\\<ok\\>\\|\\<done\\>\\|\\<success\\>\\|✓\\|✔"
          syn match MsgPath "[a-zA-Z]:\\\\[^\n]*"
          hi def link MsgError DiagnosticError
          hi def link MsgWarn  DiagnosticWarn
          hi def link MsgInfo  DiagnosticInfo
          hi def link MsgSuccess DiagnosticOk
          hi def link MsgPath  Underlined
        ]])
      end)
      Snacks.win({
        buf = buf,
        width = 0.6,
        height = 0.6,
        enter = true,
        border = "rounded",
        title = " Messages History ",
        title_pos = "center",
        wo = { number = true, relativenumber = true },
      })
    end, desc = "Messages" },
    { "<leader>sK", function() Snacks.picker.marks() end, desc = "Jump to Mark" },
    { "<leader>so", function() Snacks.picker.options() end, desc = "Options" },
    { "<leader>sR", function() Snacks.picker.resume() end, desc = "Resume" },
    { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
    { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },

    -- LSP symbols (buffer-local registered in mason.lua, but also provide global fallback)
    { "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "Goto Symbol (Document)" },
    { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "Goto Symbol (Workspace)" },

    -- notifier
    { "<leader>sn", "", desc = "+notify" },
    { "<leader>snh", function() Snacks.notifier.show_history() end, desc = "Notification History" },
    { "<leader>snd", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
  },
}
