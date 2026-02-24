## 1. 插件声明（dap-cs.lua 骨架）

- [x] 1.1 创建 `lua/plugins/dap-cs.lua`，声明 `mfussenegger/nvim-dap` 插件条目，设置懒加载
- [x] 1.2 在同一文件中声明 `jay-babu/mason-nvim-dap.nvim`，依赖 `mason-org/mason.nvim` 和 `nvim-dap`
- [x] 1.3 在同一文件中声明 `rcarriga/nvim-dap-ui`，依赖 `nvim-dap` 和 `nvim-nio`
- [x] 1.4 在同一文件中声明 `theHamsta/nvim-dap-virtual-text`，依赖 `nvim-dap` 和 `nvim-treesitter`

## 2. Mason 自动安装 netcoredbg

- [x] 2.1 在 `dap-cs.lua` 的 config 函数中调用 `require("mason-nvim-dap").setup({ ensure_installed = { "netcoredbg" }, handlers = {} })`
- [ ] 2.2 启动 Neovim，验证 Mason 自动触发 `netcoredbg` 安装（或已安装时静默跳过）

## 3. netcoredbg 适配器注册

- [x] 3.1 通过 `mason-registry.get_package("netcoredbg"):get_install_path()` 动态获取适配器路径
- [x] 3.2 将 `dap.adapters.coreclr` 注册为 `executable` 类型，command 指向 `netcoredbg` 可执行文件，args 包含 `--interpreter=vscode`

## 4. Launch Configuration

- [x] 4.1 实现 DLL 路径检测辅助函数：调用 `cs_solution.find_sln()` → glob `**/bin/Debug/**/*.dll` → 取第一个匹配或回退到手动输入默认值
- [x] 4.2 注册 `dap.configurations.cs` 条目 `.NET: Launch Program`（type=coreclr，request=launch，使用辅助函数填充 program）
- [x] 4.3 注册 `dap.configurations.cs` 条目 `.NET: Launch ASP.NET`（在 Launch Program 基础上添加 `env = { ASPNETCORE_ENVIRONMENT = "Development" }`）

## 5. 调试 UI 配置

- [x] 5.1 调用 `require("nvim-dap-virtual-text").setup()`
- [x] 5.2 调用 `require("dapui").setup()`，配置默认布局（侧边栏显示变量/调用栈，底部显示控制台/断点）
- [x] 5.3 通过 `dap.listeners.after.event_initialized` 在调试会话初始化后自动调用 `dapui.open()`
- [x] 5.4 通过 `dap.listeners.before.event_terminated` 和 `event_exited` 在会话结束前调用 `dapui.close()`

## 6. 调试快捷键（LspAttach）

- [x] 6.1 在 `dap-cs.lua` config 中注册 `LspAttach` autocmd，过滤 `client.name == "roslyn"`
- [x] 6.2 在 autocmd 回调中为当前 buffer 注册以下 keymap（`<leader>d` 前缀）：
  - `<leader>dc` → `dap.continue()`（启动/继续）
  - `<leader>do` → `dap.step_over()`（单步跳过）
  - `<leader>di` → `dap.step_into()`（单步进入）
  - `<leader>dO` → `dap.step_out()`（单步退出）
  - `<leader>db` → `dap.toggle_breakpoint()`（切换断点）
  - `<leader>dB` → `dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))`（条件断点）
  - `<leader>dr` → `dap.repl.open()`（打开 REPL）
  - `<leader>du` → `dapui.toggle()`（手动切换 UI）
- [x] 6.3 为上述 keymap 添加 `which-key` 可识别的 `desc` 字段

## 8. launch.json 支持

- [x] 8.1 在项目的 `.vscode/launch.json` 中添加 `type: "coreclr"` 的 launch 条目，指定正确的 `program` 路径（如 `${workspaceFolder}/Output/Weldone.dll`）
- [x] 8.2 在 `core/dap.lua` 的 `LspAttach` 回调中，通过 `cs_solution.find_sln()` 定位项目根目录，查找 `.vscode/launch.json`
- [x] 8.3 若 launch.json 存在，调用 `dap.ext.vscode.load_launchjs(path, { coreclr = {"cs"} })` 加载配置
- [x] 8.4 用 `loaded_launch_configs` 表防止同一 JSON 在同次会话中被重复加载
- [x] 8.5 若 launch.json 不存在，回退到内置的 pick_dll 配置（`dap.configurations.cs` 已设置则跳过）
- [ ] 8.6 验证：打开 weldone 项目的 `.cs` 文件后，`<leader>dc` 菜单中出现 "C#: 启动 Weldone (nvim-dap)" 条目

- [ ] 7.1 打开一个 .NET Console App 的 `.cs` 文件，确认 Roslyn 附加后调试快捷键可用（`:map <buffer> <leader>dc` 有输出）
- [ ] 7.2 设置断点，执行 `<leader>dc`，选择 `.NET: Launch Program`，确认 dap-ui 面板打开、程序在断点处暂停
- [ ] 7.3 执行 `<leader>do` 单步，确认 virtual text 在当前行显示变量值
- [ ] 7.4 继续执行至结束，确认 dap-ui 面板自动关闭
- [ ] 7.5 打开一个 ASP.NET 项目的 `.cs` 文件，选择 `.NET: Launch ASP.NET` 配置，确认进程携带 `ASPNETCORE_ENVIRONMENT=Development`
