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

### D4: DLL 路径检测策略

**选择**: 三级回退策略：
1. 用 `cs_solution.lua.find_sln()` 定位 `.sln` 目录
2. 用 `vim.fn.glob(sln_dir .. "/**/bin/Debug/**/*.dll", false, true)` 展开候选列表
3. 取第一个匹配项作为 `vim.fn.input()` 默认值，用户可手动修改

```lua
request = function()
  local sln = require("cs_solution").find_sln()
  local root = sln and vim.fn.fnamemodify(sln, ":h") or vim.fn.getcwd()
  local dlls = vim.fn.glob(root .. "/**/bin/Debug/**/*.dll", false, true)
  local default = #dlls > 0 and dlls[1] or root .. "/bin/Debug/net8.0/App.dll"
  return vim.fn.input("DLL path: ", default, "file")
end
```

**理由**: 自动检测减少用户输入，同时保留手动修正能力，兼容 .NET 6/7/8 等不同 TFM 目录。

**放弃的方案**: 完全手动输入 → 用户体验差；完全自动选择 → 多项目 solution 时选择不可靠。

---

### D5: ASP.NET 配置通过独立 launch entry 区分

**选择**: 为 `cs` filetype 注册两条独立的 `dap.configurations.cs` 条目：
- `".NET: Launch Program"` — 通用 Console/Library
- `".NET: Launch ASP.NET"` — 额外注入 `ASPNETCORE_ENVIRONMENT = "Development"`

**理由**: 两种场景环境变量需求不同，分开声明语义清晰，用户在 `dap.continue()` 时可明确选择。

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
