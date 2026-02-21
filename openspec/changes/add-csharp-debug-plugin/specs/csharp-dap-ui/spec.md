## ADDED Requirements

### Requirement: nvim-dap-ui 调试面板集成
系统 SHALL 声明并配置 `rcarriga/nvim-dap-ui`，在调试会话开始时自动打开调试面板，会话结束时自动关闭。

#### Scenario: 调试会话启动时面板自动打开
- **WHEN** 用户通过 `dap.continue()` 启动调试会话
- **THEN** dap-ui 面板（变量、调用栈、断点、控制台）自动展开

#### Scenario: 调试会话结束时面板自动关闭
- **WHEN** 调试进程正常结束或被终止
- **THEN** dap-ui 面板自动收起，恢复原窗口布局

### Requirement: nvim-dap-virtual-text 内联变量显示
系统 SHALL 声明 `theHamsta/nvim-dap-virtual-text` 并在 setup 时启用，使变量当前值以 virtual text 形式显示在对应代码行右侧。

#### Scenario: 断点暂停时显示变量值
- **WHEN** 调试器在断点处暂停
- **THEN** 当前作用域内的变量值以 virtual text 显示在变量声明/赋值行右侧

#### Scenario: 调试会话结束后清除 virtual text
- **WHEN** 调试会话终止
- **THEN** 所有 virtual text 标注被清除，编辑器回到普通显示状态

### Requirement: 调试快捷键仅在 C# buffer 上激活
系统 SHALL 在 Roslyn LSP 的 `on_attach` 回调中注册调试相关 keymap，确保这些快捷键只在附加了 Roslyn LSP 的 buffer 上生效。

#### Scenario: 在 .cs 文件中快捷键可用
- **WHEN** 用户打开一个被 Roslyn LSP 附加的 `.cs` 文件
- **THEN** 调试快捷键（继续、单步、断点切换等）在该 buffer 上可用

#### Scenario: 在非 C# 文件中快捷键不干扰
- **WHEN** 用户打开一个非 `.cs` 文件
- **THEN** C# 调试快捷键不存在于该 buffer，不与其他语言快捷键冲突
