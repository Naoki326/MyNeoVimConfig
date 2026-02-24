## Context

当前 Neovim 配置已有：
- `seblj/roslyn.nvim` 提供 C# LSP（代码补全、诊断、跳转）
- `mason-org/mason.nvim` 管理工具链，使用自定义 registry（含 Roslyn LSP）
- `lua/cs_solution.lua` 提供 `.sln` / `.csproj` 解析与文件归属判断
- Roslyn LSP 当前在 `roslyn.lua` 中通过 `require("roslyn").setup()` 配置，**无 `on_attach` 回调**

需要在此基础上叠加 DAP 调试能力，支持 .NET Console App 和 ASP.NET，且不破坏现有 LSP 行为。

---

## Goals / Non-Goals

**Goals:**
- 通过 `nvim-dap` + `netcoredbg` 实现 .NET / ASP.NET 断点调试
- 调试 UI 与 virtual text 自动随会话开关
- 调试快捷键仅在 Roslyn LSP 附加的 buffer 上生效
- Mason 自动管理 `netcoredbg` 安装

**Non-Goals:**
- 不支持 Unity 调试（需要不同适配器）
- 不引入 `launch.json` 文件解析（手动配置即可覆盖需求）
- 不修改 `cs_solution.lua` 自身逻辑

---

## Decisions

### D1: 所有 DAP 配置集中到单一文件 `lua/plugins/dap-cs.lua`

**选择**: 新建 `lua/plugins/dap-cs.lua`，包含所有 DAP 相关插件声明与配置。

**理由**: 保持与现有每语言/功能一个 plugin 文件的结构一致（如 `roslyn.lua`）。将 DAP 配置与 LSP 配置解耦，避免 `roslyn.lua` 承担过多职责。

**放弃的方案**: 在 `roslyn.lua` 中直接内联 DAP 配置 → 造成两种关注点混合，未来维护困难。

---

### D2: 调试快捷键通过 `LspAttach` autocmd 挂载，过滤 `roslyn` 服务名

**选择**: 在 `dap-cs.lua` 的 `config` 函数内注册 `LspAttach` autocmd，检查 `client.name == "roslyn"`，再为该 buffer 设置调试 keymap。

```lua
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("dap-cs-attach", { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client or client.name ~= "roslyn" then return end
    -- 注册调试 keymap...
  end,
})
```

**理由**:
- 避免修改 `roslyn.lua`（最小化变更范围）
- DAP 配置完全自包含，卸载 `dap-cs.lua` 时自动失效
- `roslyn.nvim` 插件的 setup 接口不直接暴露 `on_attach`，autocmd 是更可靠的方式

**放弃的方案**: 修改 `roslyn.lua` 添加 `on_attach` → 耦合两个不同关注点。

---

### D3: 使用 `jay-babu/mason-nvim-dap.nvim` 管理 netcoredbg 安装

**选择**: 声明 `mason-nvim-dap.nvim` 作为 `nvim-dap` 的依赖，调用 `require("mason-nvim-dap").setup({ ensure_installed = { "netcoredbg" }, handlers = {} })`。

**理由**: 与现有 Mason 体系一致，`ensure_installed` 在首次启动时自动下载，无需手动执行 `:MasonInstall`。

**适配器路径**: 通过 `require("mason-registry").get_package("netcoredbg"):get_install_path()` 动态解析，不硬编码路径。

**放弃的方案**: 手动指定固定路径 → Windows/Linux 路径不同，可移植性差。

---

### D4: Launch configuration 优先从项目的 `.vscode/launch.json` 加载

**选择**: 使用 `nvim-dap` 内置的 `dap.ext.vscode.load_launchjs(path, { coreclr = {"cs"} })` 在 `LspAttach` 时加载项目目录下的 `.vscode/launch.json`，以 `cs_solution.find_sln()` 推断项目根目录。

```lua
-- 在 LspAttach 回调中（已知 root）：
local launch_json = root .. "/.vscode/launch.json"
if vim.fn.filereadable(launch_json) == 1 then
  require("dap.ext.vscode").load_launchjs(launch_json, { coreclr = { "cs" } })
end
```

**理由**: launch 配置与项目共存，版本控制友好，团队成员共享同一配置；避免在 Neovim 配置里硬编码各项目路径。`load_launchjs` 支持 `${workspaceFolder}`、`${command:pickProcess}` 等 VSCode 变量的自动解析。

**仅加载 `coreclr` type**: `type: "dotnet"` 和 `type: "chrome"` 的条目会被过滤，不影响 C# 调试配置列表。

**重复加载防护**: 用 `loaded_launch_configs` 表记录已加载路径，同一 JSON 在同次会话中只加载一次（避免多 buffer attach 时重复追加）。

**放弃的方案**: 在 `core/dap.lua` 中硬编码 glob + input → 每个项目路径不同，需频繁修改 Neovim 配置。

---

### D5: 项目 launch.json 中需包含 `coreclr` type 的 launch 条目

**选择**: 对于使用非标准输出目录的项目（如 weldone 使用 `Output/` 而非 `bin/Debug/`），在项目的 `.vscode/launch.json` 中手动添加 `coreclr` launch 条目，指定准确的 `program` 路径。

```json
{
  "name": "C#: 启动 Weldone (nvim-dap)",
  "type": "coreclr",
  "request": "launch",
  "program": "${workspaceFolder}/Output/Weldone.dll",
  "cwd": "${workspaceFolder}",
  "stopAtEntry": false,
  "env": { "ASPNETCORE_ENVIRONMENT": "Development" }
}
```

**理由**: 输出目录是项目级配置，写在 `launch.json` 里比在 Neovim 配置里 glob 检测更准确可靠。

---

### D6: 无 launch.json 时回退到 pick_dll 内置配置

**选择**: 若当前项目根目录下不存在 `.vscode/launch.json`，则保留原有的 `dap.configurations.cs` 内置兜底配置（glob 检测 + input 预填充）。

**理由**: 确保在没有 `.vscode/launch.json` 的项目中调试仍可用，不强制要求每个项目都有配置文件。

---

## Risks / Trade-offs

| 风险 | 缓解措施 |
|------|---------|
| `netcoredbg` 在 Windows 上需要 VC++ 运行时 | Mason 安装时会自动处理；用户需有 .NET SDK |
| 多个 `.dll` 匹配时 glob 取第一个可能选错 | 保留 `vim.fn.input()` 让用户确认/修改 |
| `LspAttach` 事件触发时 `mason-nvim-dap` 可能尚未完成安装 | 安装在首次启动完成；attach 发生在文件打开时，时序正常 |
| `dap-ui` 自动开关影响 Neovim 窗口布局恢复 | 使用 `dapui.close()` 而非 `dapui.toggle()`，可预期关闭 |

---

## Migration Plan

1. 创建 `lua/plugins/dap-cs.lua`
2. 首次启动 Neovim → Mason 自动安装 `netcoredbg`（约需网络连接）
3. 打开任意 `.cs` 文件 → Roslyn attach → 调试 keymap 激活
4. 使用 `<leader>dc` 启动调试，选择 launch configuration

**回滚**: 删除 `lua/plugins/dap-cs.lua` 即可完全回滚，无其他文件被修改。

---

## Open Questions

（无）
