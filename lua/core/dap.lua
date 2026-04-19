-- DAP 核心初始化
-- 由 init.lua 在 VeryLazy 事件后调用
-- 适配器注册由 core/dap_config.lua 控制（netcoredbg / sharpdbg / easydotnet）

local M = {}

-- 记录已加载的 launch.json 路径，防止多 buffer attach 时重复追加配置
local loaded = {}

-- 从目录向上查找 .sln 文件
local function find_sln(start_dir)
  local dir = vim.fn.fnamemodify(start_dir or vim.fn.getcwd(), ":p")
  dir = dir:gsub("\\", "/"):gsub("/$", "")
  for _ = 1, 6 do
    local slns = vim.fn.glob(dir .. "/*.sln", false, true)
    if #slns > 0 then return slns[1] end
    local parent = vim.fn.fnamemodify(dir, ":h"):gsub("\\", "/"):gsub("/$", "")
    if parent == dir then break end
    dir = parent
  end
  return nil
end

-- 从 buffer 所在目录向上查找 .sln，返回解决方案根目录
local function project_root(buf)
  local start = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":h")
  local sln = find_sln(start)
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

-- 启动 dotnet watch run（进程内热重载）并在 3 秒后 attach
local function hot_reload(dap)
  vim.cmd("silent! wa")
  local root = vim.fn.getcwd()
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
  local dap_config = require("core.dap_config")

  -- ── 0. 根据配置注册调试适配器 ─────────────────────────────────────────────
  if dap_config.debugger == "netcoredbg" then
    local ok, settings = pcall(require, "mason.settings")
    if ok then
      local root = settings.current.install_root_dir
      local exe = vim.fn.has("win32") == 1 and "netcoredbg.exe" or "netcoredbg"
      local cmd = root .. "/packages/netcoredbg/netcoredbg/" .. exe
      dap.adapters.coreclr = {
        type = "executable",
        command = cmd,
        args = { "--interpreter=vscode" },
      }
      if vim.fn.executable(cmd) == 0 then
        vim.notify("DAP: netcoredbg not found. Run :MasonInstall netcoredbg", vim.log.levels.WARN)
      end
    end
  elseif dap_config.debugger == "sharpdbg" then
    local sharpdbg = require("lazy.core.config").plugins["sharpdbg"]
    if sharpdbg then
      -- 尝试两种可能的编译输出路径
      local cmd = sharpdbg.dir .. "/artifacts/bin/SharpDbg.Cli/Debug/SharpDbg.Cli.exe"
      cmd = cmd:gsub("/", "\\")
      if vim.fn.executable(cmd) == 0 then
        -- 备选：net10.0 子目录
        cmd = sharpdbg.dir .. "/artifacts/bin/SharpDbg.Cli/Debug/net10.0/SharpDbg.Cli.exe"
        cmd = cmd:gsub("/", "\\")
      end
      if vim.fn.executable(cmd) == 1 then
        dap.adapters.coreclr = {
          type = "executable",
          command = cmd,
          args = { "--interpreter=vscode" },
        }
      else
        vim.notify("DAP: sharpdbg not found in " .. cmd .. ". Run `dotnet build`", vim.log.levels.WARN)
      end
    else
      vim.notify("DAP: sharpdbg plugin not installed", vim.log.levels.WARN)
    end
  end
  -- easydotnet 模式：easy-dotnet.nvim 在自身 setup 中注册适配器

  -- 为 easy-dotnet 的 Dotnet debug 命令注册适配器（所有模式都需此适配器）
  dap.adapters["easy-dotnet"] = function(callback, config)
    if not config.port then
      error("Debugger failed to start")
      return
    end
    callback({ type = "server", host = "127.0.0.1", port = config.port })
  end

  -- 自定义断点/调试图标
  vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = "" })
  vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DapBreakpointCondition", linehl = "", numhl = "" })
  vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DapBreakpointRejected", linehl = "", numhl = "" })
  vim.fn.sign_define("DapLogPoint", { text = "▶", texthl = "DapLogPoint", linehl = "", numhl = "" })
  vim.fn.sign_define("DapStopped", { text = "→", texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "" })

  -- 断点颜色
  vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#e51400" })
  vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = "#ffcc00" })
  vim.api.nvim_set_hl(0, "DapBreakpointRejected", { fg = "#808080" })
  vim.api.nvim_set_hl(0, "DapLogPoint", { fg = "#3b8eea" })
  vim.api.nvim_set_hl(0, "DapStopped", { fg = "#ffcc00" })
  vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#2d2d00" })

  -- ── 1. dap-ui ────────────────────────────────────────────────────────────
  local ok_ui, dapui = pcall(require, "dapui")
  if ok_ui then
    dapui.setup()
    dap.listeners.after.event_initialized["dapui"]  = function() dapui.open()  end
    dap.listeners.before.event_terminated["dapui"]  = function() dapui.close() end
    dap.listeners.before.event_exited["dapui"]      = function() dapui.close() end
  end

  -- ── 1.5 调试停止时自动跳转到当前帧 ───────────────────────────────────────
  local function jump_to_frame(session)
    local frame = session and session.current_frame
    if not frame or not frame.source or not frame.source.path then return end
    vim.schedule(function()
      local path = frame.source.path
      local bufnr = vim.fn.bufnr(path)
      if bufnr == -1 then
        vim.cmd("edit " .. vim.fn.fnameescape(path))
        bufnr = vim.api.nvim_get_current_buf()
      end
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == bufnr then
          vim.api.nvim_set_current_win(win)
          break
        end
      end
      local col = math.max(0, (frame.column or 1) - 1)
      pcall(vim.api.nvim_win_set_cursor, 0, { frame.line, col })
      vim.cmd("normal! zz")
    end)
  end

  dap.listeners.after.event_stopped["jump_to_frame"] = function(session, _)
    -- 等待 stackTrace 完成后 current_frame 才可用
    vim.defer_fn(function() jump_to_frame(session) end, 150)
  end

  -- ── 2. virtual text ──────────────────────────────────────────────────────
  local ok_vt, vt = pcall(require, "nvim-dap-virtual-text")
  if ok_vt then vt.setup() end

  -- ── 4. C# 调试快捷键（buffer-local，Roslyn 连接后注册）──────────────────
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("dap-cs", { clear = true }),
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if not client or client.name ~= "roslyn" then return end

      local map = function(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = "DAP: " .. desc })
      end

      -- netcoredbg / sharpdbg 模式：加载 launch.json 或设兜底配置
      if dap_config.debugger ~= "easydotnet" then
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
      end

      -- Continue / Pick Config（vim.ui.select 已由 snacks.picker 接管）
      local function continue_or_pick()
        dap.continue()
      end

      map("<leader>dc", continue_or_pick, "Continue / Pick Config")
      map("<F5>",       continue_or_pick, "Continue / Pick Config")

      -- Step
      map("<leader>do", dap.step_over, "Step Over")
      map("<F10>",      dap.step_over, "Step Over")

      map("<leader>di", dap.step_into, "Step Into")
      map("<F11>",      dap.step_into, "Step Into")

      map("<leader>dO", dap.step_out,  "Step Out")
      map("<S-F11>",    dap.step_out,  "Step Out")

      -- Breakpoint
      map("<leader>db", dap.toggle_breakpoint, "Toggle Breakpoint")
      map("<F9>",       dap.toggle_breakpoint, "Toggle Breakpoint")

      map("<leader>dB", function()
        dap.set_breakpoint(vim.fn.input("Condition: "))
      end, "Conditional Breakpoint")

      -- Terminate
      map("<leader>dq", function()
        dap.terminate()
        if ok_ui then dapui.close() end
      end, "Terminate")
      map("<S-F5>", function()
        dap.terminate()
        if ok_ui then dapui.close() end
      end, "Terminate")

      -- Set Variable
      map("<leader>dE", function() set_variable(dap) end, "Set Variable")

      -- Hot Reload
      map("<leader>dh", function() hot_reload(dap) end, "Hot Reload (dotnet watch)")

      -- Jump to current frame
      map("<leader>dj", function()
        jump_to_frame(dap.session())
      end, "Jump to Current Frame")

      -- Set next statement (jump execution to cursor line without running intermediate code)
      -- Note: netcoredbg does NOT support this; only works with debuggers that support GotoTargetRequest
      map("<leader>dg", function()
        if not dap.session() then
          vim.notify("DAP: No active debug session", vim.log.levels.WARN)
          return
        end
        dap.goto_()
      end, "Go to Line (Set Next Statement)")

      -- REPL / UI
      map("<leader>dr", dap.repl.open,                            "Open REPL")
      map("<leader>du", function() require("dapui").toggle() end, "Toggle UI")

      -- DAP 信息查看（由 dapui 或原生命令提供）
      map("<leader>dl", function() dap.list_breakpoints() end, "List Breakpoints")
    end,
  })
end

return M
