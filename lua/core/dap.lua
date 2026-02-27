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

-- 交互式修改调试变量值
-- 以光标下 word 预填充变量名，通过 DAP setVariable 修改当前帧各 scope 中的变量
local function set_variable(dap)
  local session = dap.session()
  if not session then
    vim.notify("DAP: No active debug session", vim.log.levels.WARN)
    return
  end
  local frame = session.current_frame
  if not frame then
    vim.notify("DAP: No current frame", vim.log.levels.WARN)
    return
  end

  local cword = vim.fn.expand("<cword>")
  vim.ui.input({ prompt = "Variable name: ", default = cword }, function(var_name)
    if not var_name or var_name == "" then return end
    vim.ui.input({ prompt = var_name .. " = " }, function(new_val)
      if new_val == nil then return end
      -- 获取当前帧的所有 scope，逐一尝试 setVariable
      session:request("scopes", { frameId = frame.id }, function(err, resp)
        if err or not (resp and resp.scopes) then
          vim.notify("DAP: Cannot get scopes: " .. tostring(err), vim.log.levels.ERROR)
          return
        end
        local scopes = resp.scopes
        local function try_scope(i)
          if i > #scopes then
            vim.notify("DAP: Variable '" .. var_name .. "' not found in any scope", vim.log.levels.WARN)
            return
          end
          session:request("setVariable", {
            variablesReference = scopes[i].variablesReference,
            name               = var_name,
            value              = new_val,
          }, function(set_err, _)
            if set_err then
              try_scope(i + 1)
            else
              vim.notify("DAP: " .. var_name .. " = " .. new_val, vim.log.levels.INFO)
              pcall(function() require("dapui").open() end)
            end
          end)
        end
        try_scope(1)
      end)
    end)
  end)
end

-- 启动 dotnet watch run（进程内热重载）并在 3 秒后弹出 attach 进程选择器
-- 注意：热重载后调试器 PDB 不同步，已热更新方法内的断点可能偏移
local function hot_reload(dap, root)
  vim.cmd("silent! wa")
  vim.fn.jobstart(
    { "dotnet", "watch", "run", "--project", root, "--non-interactive" },
    { detach = true }
  )
  vim.notify(
    "DAP: dotnet watch started. Attaching in 3s...\n" ..
    "(Breakpoints in hot-reloaded methods may drift — PDB not synced)",
    vim.log.levels.INFO
  )
  vim.defer_fn(function()
    dap.run({
      type      = "coreclr",
      name      = ".NET: Attach to Process",
      request   = "attach",
      processId = require("dap.utils").pick_process,
    })
  end, 3000)
end

function M.setup()
  local dap = require("dap")

  -- ── 1. coreclr 适配器 ────────────────────────────────────────────────────
  local ok, settings = pcall(require, "mason.settings")
  -- if ok then
  --   local root = settings.current.install_root_dir
  --   local exe  = vim.fn.has("win32") == 1 and "netcoredbg.exe" or "netcoredbg"
  --   local cmd  = root .. "/packages/netcoredbg/netcoredbg/" .. exe
  --
  --   dap.adapters.coreclr = {
  --     type = "executable",
  --     command = cmd,
  --     args = { "--interpreter=vscode" },
  --   }
  --
  --   if vim.fn.executable(cmd) == 0 then
  --     vim.notify("DAP: netcoredbg not found. Run :MasonInstall netcoredbg", vim.log.levels.WARN)
  --   end
  -- end
  local sharpdbg= require("lazy.core.config").plugins["sharpdbg"]
  if sharpdbg ~= nil then
    local dbgDir = sharpdbg.dir
    local cmd = dbgDir .. [[/artifacts/bin/SharpDbg.Cli/Debug/]] .. "SharpDbg.Cli.exe"

    dap.adapters.coreclr = {
        type = "executable",
        command = cmd,
        args = { "--interpreter=vscode" }
    }
    if vim.fn.executable(cmd) == 0 then
      vim.notify("DAP: sharpdbg not found in ." .. cmd, vim.log.levels.WARN)
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

      -- attach 配置常驻（不依赖 launch.json，始终可用）
      if not dap.configurations.cs then dap.configurations.cs = {} end
      local has_attach = false
      for _, c in ipairs(dap.configurations.cs) do
        if c.request == "attach" and c.name == ".NET: Attach to Process" then
          has_attach = true; break
        end
      end
      if not has_attach then
        table.insert(dap.configurations.cs, {
          type      = "coreclr",
          name      = ".NET: Attach to Process",
          request   = "attach",
          processId = require("dap.utils").pick_process,
        })
      end

      -- 4b. 快捷键（buffer 局部，<leader>d 前缀 + F 键双轨）
      local map = function(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = "DAP: " .. desc })
      end

      -- ── Continue / Pick Config ──────────────────────────────────────────
      local function continue_or_pick()
        if dap.session() then
          dap.continue()
        elseif ok_tel then
          require("telescope").extensions.dap.configurations({
            language_filter = function(lang) return lang == "cs" end,
          })
        else
          dap.continue()
        end
      end

      -- 4b. 快捷键（buffer 局部，<leader>d 前缀）
      local map = function(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = "DAP: " .. desc })
      end

      -- 启动：无活跃会话时用 Telescope 选配置，有会话时直接继续
      map("<leader>dc", continue_or_pick, "Continue / Pick Config")
      map("<F5>",       continue_or_pick, "Continue / Pick Config")

      -- ── Step ───────────────────────────────────────────────────────────
      map("<leader>do", dap.step_over, "Step Over")
      map("<F10>",      dap.step_over, "Step Over")

      map("<leader>di", dap.step_into, "Step Into")
      map("<F11>",      dap.step_into, "Step Into")

      map("<leader>dO", dap.step_out,  "Step Out")
      map("<S-F11>",    dap.step_out,  "Step Out")

      -- ── Breakpoint ─────────────────────────────────────────────────────
      map("<leader>db", dap.toggle_breakpoint, "Toggle Breakpoint")
      map("<F9>",       dap.toggle_breakpoint, "Toggle Breakpoint")

      map("<leader>dB", function()
        dap.set_breakpoint(vim.fn.input("Condition: "))
      end, "Conditional Breakpoint")

      -- ── Terminate ──────────────────────────────────────────────────────
      map("<leader>dq", function()
        dap.terminate()
        if ok_ui then dapui.close() end
      end, "Terminate")
      map("<S-F5>", function()
        dap.terminate()
        if ok_ui then dapui.close() end
      end, "Terminate")

      -- ── Set Variable ───────────────────────────────────────────────────
      map("<leader>dE", function() set_variable(dap) end, "Set Variable")

      -- ── Hot Reload (dotnet watch + attach) ─────────────────────────────
      map("<leader>dh", function() hot_reload(dap, root) end, "Hot Reload (dotnet watch)")

      -- ── REPL / UI ──────────────────────────────────────────────────────
      map("<leader>dr", dap.repl.open,                            "Open REPL")
      map("<leader>du", function() require("dapui").toggle() end, "Toggle UI")

      -- ── Telescope 扩展快捷键 ───────────────────────────────────────────
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
