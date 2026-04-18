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
    -- 监听 roslyn.nvim 确定或切换 solution 的事件，同步初始化 cs_solution
    vim.api.nvim_create_autocmd("User", {
      pattern = "RoslynOnInit",
      callback = function(ev)
        if ev.data.type ~= "solution" then return end

        local cs_sln = require("cs_solution")
        -- 重置状态（支持 sln 切换时重新加载）
        cs_sln._initialized = false
        cs_sln._projects = {}
        cs_sln._file_cache = {}

        if cs_sln.init(ev.data.target) then
          vim.schedule(function()
            pcall(function()
              require("neo-tree.sources.manager").refresh("filesystem")
            end)
          end)
        end
      end,
    })

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

      -- 注册自定义组件
      components = {
        ---显示 .cs 文件是否被解决方案编译的状态图标
        cs_sln_status = function(config, node, _state)
          if node.type ~= "file" then return {} end
          local path = node.path or ""
          if not path:match("%.cs$") then return {} end

          local cs_sln = require("cs_solution")
          local in_sln = cs_sln.is_in_solution(path)

          if in_sln == true then
            return { text = config.symbol_in, highlight = config.hl_in }
          elseif in_sln == false then
            return { text = config.symbol_out, highlight = config.hl_out }
          end
          -- nil：未初始化，不显示
          return {}
        end,
      },

      -- 覆盖 file 类型的渲染顺序，在 icon 后加入状态图标
      renderers = {
        file = {
          { "indent" },
          { "icon" },
          {
            "cs_sln_status",
            symbol_in = "● ", -- 绿点：在解决方案中
            hl_in = "DiagnosticOk",
            symbol_out = "○ ", -- 灰圈：不在解决方案中
            hl_out = "DiagnosticWarn",
          },
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
