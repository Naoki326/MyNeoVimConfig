## 1. F 键标准键位

- [x] 1.1 在 `lua/core/dap.lua` 的 `map()` 调用段，追加 `<F5>` 绑定：无会话时打开 Telescope 配置选择器，有会话时调用 `dap.continue()`
- [x] 1.2 追加 `<F10>` 绑定：调用 `dap.step_over()`
- [x] 1.3 追加 `<F11>` 绑定：调用 `dap.step_into()`
- [x] 1.4 追加 `<S-F11>` 绑定：调用 `dap.step_out()`
- [x] 1.5 追加 `<F9>` 绑定：调用 `dap.toggle_breakpoint()`
- [x] 1.6 追加 `<S-F5>` 绑定：调用 `dap.terminate()`，并在回调中关闭 dap-ui
- [x] 1.7 验证所有 F 键仅注册为 buffer 局部键位（`buffer = ev.buf`），现有 `<leader>d` 键位不受影响

## 2. Set Variable（交互式修改变量值）

- [x] 2.1 在 `lua/core/dap.lua` 中定义局部函数 `set_variable()`
- [x] 2.2 函数开头加 guard：无会话时提示 "No active debug session"
- [x] 2.3 用 `vim.fn.expand("<cword>")` 获取光标下变量名作为预填充
- [x] 2.4 调用 `vim.ui.input({ prompt = "Set " .. name .. " = ", default = name })` 等待用户输入
- [x] 2.5 用户确认后，通过 `dap.session():request("setVariable", { variablesReference = ..., name = name, value = new_val }, cb)` 发送请求
- [x] 2.6 回调中：成功则 `vim.notify` 提示成功并刷新 dap-ui；失败则 `vim.notify` 显示 DAP 返回的错误消息
- [x] 2.7 追加 `<leader>dE` 绑定调用 `set_variable()`

## 3. Hot Reload（dotnet watch + attach）

- [x] 3.1 在 `dap.configurations.cs` 初始化段（launch.json 不存在时的兜底）中追加一条 attach 配置：`{ type="coreclr", name=".NET: Attach to Process", request="attach", processId=require("dap.utils").pick_process }`
- [x] 3.2 在 `lua/core/dap.lua` 中定义局部函数 `hot_reload(root)`
- [x] 3.3 函数开头调用 `vim.cmd("silent! wa")` 保存所有 buffer
- [x] 3.4 用 `vim.fn.jobstart({"dotnet", "watch", "run", "--project", root, "--non-interactive"})` 后台启动 dotnet watch
- [x] 3.5 调用 `vim.notify` 显示状态：说明 watch 已启动、3 秒后弹出 attach 选择器、并告知断点偏移风险
- [x] 3.6 用 `vim.defer_fn(3000, fn)` 延迟 3 秒后调用 `dap.run({ type="coreclr", request="attach", processId=require("dap.utils").pick_process })`
- [x] 3.7 追加 `<leader>dh` 绑定，调用 `hot_reload(project_root(ev.buf))`
