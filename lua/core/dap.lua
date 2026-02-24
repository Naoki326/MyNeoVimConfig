-- DAP 核心初始化
-- 由 init.lua 在 VeryLazy 事件后调用，确保所有插件已加载完毕

local M = {}

-- 记录已加载的 launch.json 路径，防止多 buffer attach 时重复追加配置
local loaded = {}

-- 从 buffer 所在目录向上查找 .sln，返回解决方案根目录
local function project_root(buf)
  local start = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":h")
  local sln = require("cs_solution").find_sln(start)
  return sln and vim.fn.fnamemodify(sln, ":h") or start
end

-- 无 launch.json 时的兜底：glob 检测 DLL + input 预填充
local function pick_dll(buf)
  return function()
    local root = project_root(buf):gsub("\\", "/")
    local candidates = vim.tbl_filter(function(p)
      return not p:match("[/\\]obj[/\\]")
    end, vim.fn.glob(root .. "/**/bin/Debug/**/*.dll", false, true))
    local default = candidates[1] or (root .. "/bin/Debug/net8.0/App.dll")
    return vim.fn.input("DLL path: ", default, "file")
  end
end

function M.setup()
  local dap = require("dap")

  -- ── 1. coreclr 适配器 ────────────────────────────────────────────────────
  local ok, settings = pcall(require, "mason.settings")
  if ok then
    local root = settings.current.install_root_dir
    local exe  = vim.fn.has("win32") == 1 and "netcoredbg.exe" or "netcoredbg"
    local cmd  = root .. "/packages/netcoredbg/netcoredbg/" .. exe

    dap.adapters.coreclr = {
      type = "executable",
      command = cmd,
      args = { "--interpreter=vscode" },
    }

    if vim.fn.executable(cmd) == 0 then
      vim.notify("DAP: netcoredbg not found. Run :MasonInstall netcoredbg", vim.log.levels.WARN)
    end
  end

  -- ── 2. dap-ui ────────────────────────────────────────────────────────────
  local ok_ui, dapui = pcall(require, "dapui")
  if ok_ui then
    dapui.setup()
    dap.listeners.after.event_initialized["dapui"]  = function() dapui.open()  end
    dap.listeners.before.event_terminated["dapui"]  = function() dapui.close() end
    dap.listeners.before.event_exited["dapui"]      = function() dapui.close() end
  end

  -- ── 3. virtual text ──────────────────────────────────────────────────────
  local ok_vt, vt = pcall(require, "nvim-dap-virtual-text")
  if ok_vt then vt.setup() end

  -- ── 4. 每个 C# buffer：加载 launch.json + 注册快捷键 ────────────────────
  -- 加载 telescope 扩展：dap picker + ui-select（覆盖 vim.ui.select）
  local ok_tel = pcall(require("telescope").load_extension, "dap")
  pcall(function()
    require("telescope").setup({
      extensions = {
        ["ui-select"] = require("telescope.themes").get_dropdown(),
      },
    })
    require("telescope").load_extension("ui-select")
  end)

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("dap-cs", { clear = true }),
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if not client or client.name ~= "roslyn" then return end

      -- 4a. launch.json 优先；不存在时设内置兜底（只设一次）
      local root        = project_root(ev.buf)
      local launch_json = root .. "/.vscode/launch.json"

      if vim.fn.filereadable(launch_json) == 1 then
        if not loaded[launch_json] then
          loaded[launch_json] = true
          require("dap.ext.vscode").load_launchjs(launch_json, { coreclr = { "cs" } })
        end
      elseif not dap.configurations.cs then
        local dll = pick_dll(ev.buf)
        local cwd = function() return project_root(ev.buf) end
        dap.configurations.cs = {
          { type = "coreclr", name = ".NET: Launch Program", request = "launch",
            program = dll, cwd = cwd },
          { type = "coreclr", name = ".NET: Launch ASP.NET",  request = "launch",
            program = dll, cwd = cwd, env = { ASPNETCORE_ENVIRONMENT = "Development" } },
        }
      end

      -- 4b. 快捷键（buffer 局部，<leader>d 前缀）
      local map = function(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = "DAP: " .. desc })
      end

      -- 启动：无活跃会话时用 Telescope 选配置，有会话时直接继续
      map("<leader>dc", function()
        if dap.session() then
          dap.continue()
        elseif ok_tel then
          require("telescope").extensions.dap.configurations({
            language_filter = function(lang) return lang == "cs" end,
          })
        else
          dap.continue()
        end
      end, "Continue / Pick Config")

      map("<leader>do", dap.step_over,                                       "Step Over")
      map("<leader>di", dap.step_into,                                       "Step Into")
      map("<leader>dO", dap.step_out,                                        "Step Out")
      map("<leader>db", dap.toggle_breakpoint,                               "Toggle Breakpoint")
      map("<leader>dB", function()
        dap.set_breakpoint(vim.fn.input("Condition: "))
      end,                                                                   "Conditional Breakpoint")
      map("<leader>dr", dap.repl.open,                                       "Open REPL")
      map("<leader>du", function() require("dapui").toggle() end,            "Toggle UI")

      -- Telescope 扩展快捷键
      if ok_tel then
        local ext = require("telescope").extensions.dap
        map("<leader>dl", ext.list_breakpoints, "List Breakpoints")
        map("<leader>df", ext.frames,           "Frames")
        map("<leader>dv", ext.variables,        "Variables")
      end
    end,
  })
end

return M
