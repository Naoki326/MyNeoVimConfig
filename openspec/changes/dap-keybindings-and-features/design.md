## Context

当前调试入口全部在 `lua/core/dap.lua` 的 `LspAttach` 回调里，以 `<leader>d` 前缀做 buffer 局部键位。功能相对基础：仅覆盖 continue/step/breakpoint/REPL/UI 切换。

需要解决：
1. F 键习惯缺失——从其他 IDE 迁移时肌肉记忆无法复用
2. 变量修改入口不明显——dap-ui 虽内置 `e` 键，但在普通 buffer 里无法直接触发
3. .NET 热重载——netcoredbg 不支持 `gotoTargets` 也不支持 `ApplyChanges`，需要借助 `dotnet watch` 的进程内热重载能力

**已确认不可行**：`dap.goto_()` (Set Next Statement) 需要 DAP server 实现 `supportsGotoTargetsRequest`，但本机 netcoredbg 3.1.3-1062 的 `initialize` 响应中该字段不存在，已从方案中移除。

## Goals / Non-Goals

**Goals:**

- F5/F10/F11/S-F11/F9/S-F5 与现有 `<leader>d` 双轨并存，不破坏现有习惯
- 用 `<leader>dE` 在暂停时弹出 `vim.ui.input` 修改光标下变量值
- 用 `<leader>dh` 启动 `dotnet watch run`（真正的进程内热重载），并自动弹出 attach 进程选择器

**Non-Goals:**

- 支持除 C#/coreclr 以外的语言
- 实现 Set Next Statement（netcoredbg 不支持 `gotoTargets`）
- 实现 Edit-and-Continue（需要 VS 专有协议）
- 修改 dap-ui 本身的 UI 布局或默认面板配置

## Decisions

### D1：F 键与 `<leader>d` 双轨并存

**选择**：两套键位都注册，不移除 `<leader>d`。

| F 键 | `<leader>d` | 操作 |
|------|-------------|------|
| F5 | `<leader>dc` | Continue / Pick Config |
| F10 | `<leader>do` | Step Over |
| F11 | `<leader>di` | Step Into |
| S-F11 | `<leader>dO` | Step Out |
| F9 | `<leader>db` | Toggle Breakpoint |
| S-F5 | `<leader>dq` | Terminate |
| — | `<leader>dE` | Set Variable |
| — | `<leader>dh` | Hot Reload (dotnet watch + attach) |

**理由**：F 键在终端复用器（tmux/Windows Terminal）里可能被截获，单独依赖 F 键不稳定；双轨让用户自主选择。

**备选**：仅改 `<leader>d`，放弃 F 键——被否，迁移成本高。

---

### D2：Set Variable 实现

**选择**：自定义 `set_variable()` 函数，使用 `vim.ui.input` 输入新值后调用 DAP `setVariable` 请求。

实现方式：
1. 获取光标下 word 作为变量名预填充
2. `vim.ui.input({ prompt = "Set " .. name .. " = " })` 弹出输入框
3. 通过 `dap.session():request("setVariable", {...})` 发送请求（netcoredbg 已确认支持 `supportsSetVariable: true`）
4. 回调里 `vim.notify` 结果并刷新 dap-ui

**理由**：dap-ui 的 `e` 键只能在 variables 面板内使用；从普通 buffer 触发更符合日常流程。

---

### D3：.NET Hot Reload 策略（dotnet watch + attach）

**选择**：`<leader>dh` 触发以下流程：

```
<leader>dh
  → vim.cmd("silent! wa")               -- 保存所有 buffer
  → jobstart("dotnet watch run ...")     -- 后台启动 dotnet watch（detach，独立存活）
  → vim.notify("dotnet watch started")
  → vim.defer_fn(3000, attach_picker)   -- 3 秒后弹出进程选择器
  → dap.run({ request="attach", processId=pick_process })  -- 用户选择进程后 attach
```

**dotnet watch run** 在 .NET 6+ 上支持进程内热重载（修改方法体等变更无需重启进程）。attach 后，调试器连接到该进程：
- 支持的变更（修改方法体等）→ dotnet watch 热更新，进程 PID 不变，调试器连接保持
- 不支持的变更（新增类型、改签名等）→ dotnet watch 重启进程，PID 变化，调试器连接断开，需重新 attach

**注意**：热重载后调试器 PDB 不同步，已热更新方法内的断点可能偏移——这是 netcoredbg 架构限制，在 notify 中说明。

**dotnet watch run 参数**：使用 `--non-interactive` 避免交互提示阻塞后台进程。

**备选**：重建并重启（`dotnet build` + `dap.restart()`）——降级为文档说明的手动方案，不作为主键位。

## Risks / Trade-offs

- **F 键被终端截获** → 双轨方案保底，`<leader>d` 始终可用
- **Set Variable 的变量名识别不准**（光标在复杂表达式上）→ 仅用 `<cword>` 预填充，用户可手动修改
- **dotnet watch 进程孤立**（nvim 退出后仍在运行）→ 使用 `detach = false` 让进程随 nvim job 生命周期结束，或在 notify 中提示用户手动终止
- **3 秒延迟不够**（大型项目启动慢）→ 可手动用 `<leader>dc` 重新触发 attach 配置，attach 配置常驻 `dap.configurations.cs`
- **热更新后断点偏移** → notify 中明确说明，用户知情

## Migration Plan

1. 修改 `lua/core/dap.lua`：追加 F 键绑定、`set_variable()` 函数、`hot_reload()` 函数
2. 在 `dap.configurations.cs` 中追加 `attach` 类型配置（供 Telescope 选择和 `dap.run()` 调用）
3. 无需修改 `lua/plugins/dap-cs.lua`（无新插件依赖）
4. 无破坏性变更，旧 `<leader>d` 键位全部保留

回滚：git revert 单个文件即可，无数据迁移。

## Open Questions

- Windows Terminal 是否会拦截 F5？若有问题可将 F5 改为 `<leader>dc` 保持现状。
- `dotnet watch run` 启动时间因项目规模不同，3 秒延迟是否合适？可考虑改为手动触发 attach。
