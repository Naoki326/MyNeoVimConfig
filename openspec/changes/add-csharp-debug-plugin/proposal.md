## Why

当前 Neovim 配置已有 Roslyn LSP 提供 C# 代码智能提示与诊断，但缺少调试能力，
无法在编辑器内对 .NET / ASP.NET 项目设置断点、单步执行、查看变量，开发体验不完整。

## What Changes

- 新增 `nvim-dap` 作为调试协议核心框架
- 新增 `nvim-dap-ui` 提供调试面板（变量、调用栈、断点、控制台）
- 新增 `nvim-dap-virtual-text` 在代码行内联显示变量值
- 新增 `mason-nvim-dap.nvim` 通过 Mason 自动安装 `netcoredbg`（.NET 调试适配器）
- 新增 C# DAP 配置模块（`lua/plugins/dap-cs.lua`），覆盖 .NET Console App 与 ASP.NET 两类 launch configuration
- 与 `cs_solution.lua` 联动：自动从 `.sln` 路径推断项目根目录与输出路径
- 与 Roslyn LSP 联动：仅在 `roslyn` LSP attach 的 buffer 上激活调试快捷键

## Capabilities

### New Capabilities

- `csharp-dap-core`: nvim-dap 框架集成，netcoredbg 适配器注册，Mason 自动安装
- `csharp-dap-ui`: nvim-dap-ui 调试面板与 nvim-dap-virtual-text 内联变量显示
- `csharp-dap-launch`: .NET Console App 和 ASP.NET launch configuration，自动检测 DLL 输出路径

### Modified Capabilities

（无现有 spec 需要修改）

## Impact

- **新文件**: `lua/plugins/dap-cs.lua`（包含所有 DAP 相关插件声明与配置）
- **现有文件**: `lua/plugins/roslyn.lua` — 在 LSP `on_attach` 回调中注册调试快捷键
- **依赖**: `mason.nvim`（已存在），新增 `netcoredbg` 通过 Mason 安装
- **外部工具**: `netcoredbg`（Windows 上由 Mason 下载，需 .NET SDK 已安装）
- **不涉及**: `cs_solution.lua` 逻辑本身不修改，仅在 DAP 配置中调用其 `find_sln()` 推断项目根目录
