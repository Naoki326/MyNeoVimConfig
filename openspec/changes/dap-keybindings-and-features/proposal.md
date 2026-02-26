## Why

当前 nvim-dap 键位使用纯 `<leader>d` 前缀方案，与 VS Code / Visual Studio / JetBrains 等主流 IDE 的 F 键习惯不一致，调试体验割裂。同时缺少三项实用功能：直接移动指令指针（Set Next Statement）、运行时修改变量值、以及 .NET 热重载，限制了调试效率。

## What Changes

- 在现有 `<leader>d` 键位基础上，叠加 F 键主流方案（F5/F10/F11/S-F11/F9），两套键位并存，便于从其他 IDE 迁移
- 新增 **Set Next Statement**：将调试器指令指针直接跳转到光标所在行，可跳过中间代码不执行，也可向前跳回重新执行（DAP `goto` 请求，`dap.goto_()`）
- 新增 **Set Variable**：调试暂停时，通过 `dapui` 的 `edit` 接口或 `dap.set_expression()` 交互修改当前作用域内的变量值
- 新增 **.NET Hot Reload**：调试会话中调用 `dotnet watch` 或通过 DAP `evaluate` 触发 `HotReloadAgent`，修改代码后无需重启即可生效

## Capabilities

### New Capabilities

- `dap-standard-keybindings`: 覆盖 F5/F10/F11/S-F11/F9 等主流 F 键，与现有 `<leader>d` 方案双轨并存
- ~~`dap-set-next-statement`~~：已移除，netcoredbg 不支持 DAP `gotoTargets` capability
- `dap-set-variable`: 调试暂停时交互式修改变量值，通过 dap-ui float 或 `vim.ui.input` 输入新值
- `dap-hot-reload`: 在后台启动 `dotnet watch run`（进程内热重载），并自动弹出 DAP attach 进程选择器连接到运行中的进程

### Modified Capabilities

<!-- 无现有 spec 需要修改 -->

## Impact

- `lua/core/dap.lua` — 主要改动文件：新增 F 键绑定、Set Next Statement 键位、Set Variable 函数、Hot Reload 触发逻辑
- `lua/plugins/dap-cs.lua` — 确认插件依赖完整（无需新增插件，hot reload 通过 shell 命令或 DAP evaluate 实现）
- 仅影响 `roslyn` LSP attach 后的 buffer 局部键位，不影响其他文件类型
