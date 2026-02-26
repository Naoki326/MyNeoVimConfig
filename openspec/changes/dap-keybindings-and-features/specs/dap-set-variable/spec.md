## ADDED Requirements

### Requirement: 交互式修改调试变量值
调试器 SHALL 支持在 DAP 会话暂停时，从普通编辑 buffer 触发变量值修改，无需切换焦点到 dap-ui 的 variables 面板。

实现流程：
1. 以光标下的 word（`<cword>`）作为变量名预填充输入框
2. 弹出 `vim.ui.input` 提示用户输入新值
3. 通过当前 DAP session 发送 `setVariable` 请求
4. 成功后刷新 dap-ui（若 dap-ui 已打开）

键位：`<leader>dE`（大写 E，区别于现有的小写键位）。

#### Scenario: 成功修改变量值
- **WHEN** 用户在暂停的调试会话中，光标位于变量名上，按下 `<leader>dE`，输入新值并确认
- **THEN** DAP server 更新该变量的值，dap-ui variables 面板显示更新后的值

#### Scenario: 用户取消输入
- **WHEN** 用户触发修改变量功能后，在 `vim.ui.input` 中按 Escape 或提交空内容
- **THEN** 取消操作，变量值不变，无错误提示

#### Scenario: 变量名可手动修改
- **WHEN** 用户触发修改变量功能，输入框预填充了 `<cword>` 但该词不是目标变量名
- **THEN** 用户可在输入框中清空预填充内容并手动输入正确的变量名和新值

#### Scenario: DAP server 拒绝修改
- **WHEN** `setVariable` 请求被 DAP server 拒绝（如变量为只读、类型不匹配）
- **THEN** 通过 `vim.notify` 显示 DAP 返回的错误信息，不抛出未处理异常

#### Scenario: 无活跃会话时的保护
- **WHEN** 用户在无 DAP 会话或会话未暂停时触发修改变量功能
- **THEN** 显示提示 "No active debug session"，不发生错误
