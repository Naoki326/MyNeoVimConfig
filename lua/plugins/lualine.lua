return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-tree/nvim-web-devicons", -- 图标支持
  },
  init = function()
    vim.g.lualine_laststatus = vim.o.laststatus
    if vim.fn.argc(-1) > 0 then
      -- set an empty statusline till lualine loads
      vim.o.statusline = " "
    else
      -- hide the statusline on the starter page
      vim.o.laststatus = 0
    end
  end,
  opts = function()
    -- PERF: we don't need this lualine require madness 🤷
    local lualine_require = require("lualine_require")
    lualine_require.require = require

    -- 定义自己的图标
    local icons = {
      diagnostics = {
        Error = " ",
        Warn = " ",
        Info = " ",
        Hint = " ",
      },
      git = {
        added = " ",
        modified = " ",
        removed = " ",
      },
    }

    vim.o.laststatus = vim.g.lualine_laststatus
    vim.o.statusline = nil

    -- 路径显示辅助：获取项目根目录（git root 优先，退回 cwd）
    -- 缓存到 buffer 变量，切换文件/目录时自动失效
    vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost", "DirChanged" }, {
      group = vim.api.nvim_create_augroup("LualineRootCache", { clear = true }),
      callback = function()
        vim.b.lualine_root = nil
      end,
    })
    local function normalize_path(p)
      return vim.fn.fnamemodify(p, ":p"):gsub("\\", "/")
    end
    local function get_project_root()
      local root = vim.b.lualine_root
      if not root then
        local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
        if git_root and vim.v.shell_error == 0 then
          root = normalize_path(git_root)
        else
          root = normalize_path(vim.fn.getcwd())
        end
        vim.b.lualine_root = root
      end
      return root
    end

    -- oh-my-zsh / Powerline 风格路径分段色块
    -- 注意：截图中的整高箭头不是普通的 "▶"，而是 Powerline 字符 ""。
    -- 用 nr2char 避免配置文件编码影响。
    local PATH_ARROW = vim.fn.nr2char(0xE0B0) --  右侧整高箭头
    -- 第一段左侧：Powerline 专用整高直角三角形（U+E0BA  lower_right_triangle）
    -- 行扫描验证：右边界固定（右边垂直）+ 左边界递增（斜边在左）+ 底边水平 = 直角在右下
    local PATH_LEFT = vim.fn.nr2char(0xE0BA)
    local path_colors = {
      { fg = "#1c1c1c", bg = "#005f87" }, -- 根：agnoster 蓝
      { fg = "#1c1c1c", bg = "#0087af" }, -- 二级：亮蓝
      { fg = "#1c1c1c", bg = "#d75f00" }, -- 三级：agnoster 橙
      { fg = "#1c1c1c", bg = "#008700" }, -- 四级：agnoster 绿
    }
    -- 5 个固定路径段组件（超过 4 段的部分合并到第 5 段，复用绿色）
    local MAX_PATH_SEGS = 5
    -- 共享：当前文件相对根目录的路径分段
    local function get_path_parts()
      local file = vim.fn.expand("%:p")
      if file == "" then
        return nil
      end
      local file_n = normalize_path(file)
      local root = get_project_root()
      local rel = file_n
      if vim.startswith(file_n, root) then
        rel = file_n:sub(#root + 1)
      end
      rel = rel:gsub("^/+$", "")
      local parts = vim.split(rel, "/", { plain = true })
      if #parts == 1 and parts[1] == "" then
        parts = { "/" }
      end
      return parts
    end
    local path_seg_components = {}
    for i = 1, MAX_PATH_SEGS do
      local idx = i
      local color = path_colors[math.min(i, #path_colors)]
      path_seg_components[i] = {
        function()
          local parts = get_path_parts()
          if not parts then
            return " [No Name] "
          end
          -- 第 5 段及以后合并：显示剩余全部路径
          if idx < MAX_PATH_SEGS then
            return " " .. (parts[idx] or "") .. " "
          else
            local rest = table.concat({ unpack(parts, idx) }, "/")
            if rest == "" then
              rest = parts[idx] or ""
            end
            return " " .. rest .. " "
          end
        end,
        color = color,
        -- 显式组件名：避免 lualine 数字编号冲突导致高亮组丢失
        component_name = "path_seg_" .. idx,
        -- 每段只在存在对应路径部分时显示
        cond = function()
          local parts = get_path_parts()
          if not parts then
            return idx == 1
          end
          if idx < MAX_PATH_SEGS then
            return parts[idx] ~= nil
          else
            return #parts >= MAX_PATH_SEGS
          end
        end,
        -- lualine 原生过渡分隔符：整高箭头，自动使用前后色块的背景色。
        -- 第一段左侧使用圆角；每段右侧使用箭头，形成截图中的连续色块。
        separator = {
          left = idx == 1 and PATH_LEFT or PATH_ARROW,
          right = PATH_ARROW,
        },
      }
    end

    local opts = {
      options = {
        theme = "auto",
        globalstatus = vim.o.laststatus == 3,
        disabled_filetypes = { statusline = { "dashboard", "alpha", "ministarter" } },
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch" },

        lualine_c = vim.list_extend(vim.list_extend({}, path_seg_components), {
          {
            "diagnostics",
            symbols = {
              error = icons.diagnostics.Error,
              warn = icons.diagnostics.Warn,
              info = icons.diagnostics.Info,
              hint = icons.diagnostics.Hint,
            },
          },
        }),
        lualine_x = {
          -- tab 页指示：多 tab 时显示 "1/3"（当前/总数）
          {
            "tabpages",
            fmt = function(cnt, idx)
              return " " .. idx .. "/" .. cnt .. " "
            end,
            color = { fg = "#7aa2f7" }, -- tokyonight 蓝色
            cond = function()
              return #vim.api.nvim_list_tabpages() > 1
            end,
          },
          -- stylua: ignore
          {
            function() return "  " .. require("dap").status() end,
            cond = function() return package.loaded["dap"] and require("dap").status() ~= "" end,
            color = { fg = "#bb9af7" }, -- Debug 高亮色
          },
          {
            require("lazy.status").updates,
            cond = require("lazy.status").has_updates,
            color = { fg = "#ff9e64" },
          },
          {
            "diff",
            symbols = {
              added = icons.git.added,
              modified = icons.git.modified,
              removed = icons.git.removed,
            },
            source = function()
              local gitsigns = vim.b.gitsigns_status_dict
              if gitsigns then
                return {
                  added = gitsigns.added,
                  modified = gitsigns.changed,
                  removed = gitsigns.removed,
                }
              end
            end,
          },
          "encoding",
          "fileformat",
          "filetype",
        },
        lualine_y = {
          { "progress", separator = " ", padding = { left = 1, right = 0 } },
          { "location", padding = { left = 0, right = 1 } },
        },
        lualine_z = {
          function()
            return " " .. os.date("%R")
          end,
        },
      },
      extensions = { "lazy", "mason", "nvim-tree" },
    }

    return opts
  end,
}
