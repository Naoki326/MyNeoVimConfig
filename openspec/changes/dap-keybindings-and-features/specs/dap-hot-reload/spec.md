## ADDED Requirements

### Requirement: 后台启动 dotnet watch 并 attach 调试器
调试器 SHALL 支持一键启动 `dotnet watch run` 后台进程，并在进程就绪后弹出 DAP attach 进程选择器，让用户将调试器连接到正在运行的 .NET 进程。

实现流程：
1. `vim.cmd("silent! wa")` 保存所有 buffer
2. `vim.fn.jobstart({"dotnet", "watch", "run", "--project", root, "--non-interactive"})` 后台启动
3. `vim.notify("DAP: dotnet watch started, attaching in 3s...", INFO)` 显示状态
4. `vim.defer_fn(3000, ...)` 延迟 3 秒后调用 `dap.run()` 触发 attach 配置
5. attach 配置使用 `require("dap.utils").pick_process` 让用户从进程列表中选择目标进程

键位：`<leader>dh`。

#### Scenario: 启动 watch 并成功 attach
- **WHEN** 用户在 C# buffer 按下 `<leader>dh`
- **THEN** 所有 buffer 被保存，`dotnet watch run` 在后台启动，3 秒后弹出进程选择器，用户选择进程后 nvim-dap 建立 attach 会话

#### Scenario: 保存并通知用户操作状态
- **WHEN** 用户触发热重载
- **THEN** SHALL 在 watch 启动时显示通知，让用户知晓当前状态

### Requirement: attach 配置常驻 launch 配置列表
`dap.configurations.cs` SHALL 包含一条 `request = "attach"` 的配置，名称为 `.NET: Attach to Process`，使用 `dap.utils.pick_process` 作为 `processId`，可通过 Telescope 配置选择器独立触发（不依赖 `<leader>dh`）。

#### Scenario: 通过 Telescope 手动 attach
- **WHEN** 用户通过 F5 / `<leader>dc` 打开 Telescope 配置选择器
- **THEN** 列表中包含 `.NET: Attach to Process` 配置，选中后弹出进程选择器

#### Scenario: watch 重启后重新 attach
- **WHEN** `dotnet watch` 因不支持的代码变更重启了进程，调试器连接断开
- **THEN** 用户可通过 F5 / `<leader>dc` 重新选择 attach 配置手动重连

### Requirement: 热重载限制告知
使用 `<leader>dh` 触发热重载时，SHALL 通过 `vim.notify` 明确告知用户：进程内热重载（修改方法体等）期间调试器 PDB 不同步，已热更新方法的断点可能偏移。

#### Scenario: 用户感知热重载限制
- **WHEN** `<leader>dh` 触发时
- **THEN** 通知消息中 SHALL 包含关于断点偏移风险的说明
