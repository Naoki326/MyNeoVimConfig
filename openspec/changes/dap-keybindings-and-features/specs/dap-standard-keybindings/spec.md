## ADDED Requirements

### Requirement: F 键主流调试键位
调试键位 SHALL 在现有 `<leader>d` 前缀键位之外，额外注册以下 F 键，两套键位并存：

| 键位 | 操作 |
|------|------|
| `<F5>` | Continue / Pick Config（无会话时打开 Telescope 配置选择） |
| `<F10>` | Step Over |
| `<F11>` | Step Into |
| `<S-F11>` | Step Out |
| `<F9>` | Toggle Breakpoint |
| `<C-F10>` | Set Next Statement（`dap.goto_()`） |
| `<S-F5>` | Terminate 调试会话 |

所有 F 键 SHALL 为 buffer 局部键位，仅在 roslyn LSP attach 后的 C# buffer 生效。

#### Scenario: F5 无会话时启动调试
- **WHEN** 用户在 C# buffer 按下 `<F5>` 且无活跃 DAP 会话
- **THEN** 打开 Telescope 配置选择器，列出当前项目的 launch 配置

#### Scenario: F5 有会话时继续执行
- **WHEN** 用户在 C# buffer 按下 `<F5>` 且存在已暂停的 DAP 会话
- **THEN** 调用 `dap.continue()` 恢复执行

#### Scenario: F10 单步跳过
- **WHEN** 用户按下 `<F10>` 且 DAP 会话处于暂停状态
- **THEN** 调用 `dap.step_over()`，执行当前行后在下一行暂停

#### Scenario: F11 单步进入
- **WHEN** 用户按下 `<F11>` 且 DAP 会话处于暂停状态
- **THEN** 调用 `dap.step_into()`，进入当前行的函数调用

#### Scenario: S-F11 跳出函数
- **WHEN** 用户按下 `<S-F11>` 且 DAP 会话处于暂停状态
- **THEN** 调用 `dap.step_out()`，执行至当前函数返回

#### Scenario: F9 切换断点
- **WHEN** 用户按下 `<F9>`
- **THEN** 在当前光标所在行切换断点状态（有则删除，无则添加）

#### Scenario: S-F5 终止会话
- **WHEN** 用户按下 `<S-F5>` 且存在活跃 DAP 会话
- **THEN** 调用 `dap.terminate()` 结束调试会话并关闭 dap-ui

### Requirement: 现有 `<leader>d` 键位不受影响
新增 F 键 SHALL NOT 移除或覆盖任何现有的 `<leader>d` 键位。

#### Scenario: 旧键位保持可用
- **WHEN** 用户使用任意现有 `<leader>d*` 键位
- **THEN** 行为与修改前完全相同
