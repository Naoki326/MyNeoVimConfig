## 1. 清理旧配置

- [x] 1.1 删除 `plugins/csharp.lua`（移除 `iabdelkareem/csharp.nvim` 及其内部的 `mason.setup()` 调用）
- [x] 1.2 删除 `plugins/lsp.lua`（死代码，第一行就 `return {}`）
- [x] 1.3 修改 `plugins/mason.lua`：从 `lsconfses` 表中移除 `["omnisharp"] = {}` 条目
- [x] 1.4 修改 `plugins/easy-dotnet.lua`：将 `lsp.enable` 从 `true` 改为 `false`

## 2. 新建 Roslyn LSP 配置

- [x] 2.1 新建 `plugins/roslyn.lua`，添加 `seblj/roslyn.nvim` 作为 lazy.nvim 插件条目，依赖 `mason-org/mason.nvim`
- [x] 2.2 在 `config` 函数中用 `require("mason-registry")` 检查并自动安装 `roslyn` 包（与 mason.lua 现有 `setup()` 函数保持同一模式）
- [x] 2.3 在 `config` 函数中调用 `require("roslyn").setup()`，传入 `blink.cmp` 的 capabilities（`require("blink.cmp").get_lsp_capabilities()`）
- [x] 2.4 在 roslyn.setup 中添加基础配置项并附注释：仅分析打开的文件（`dotnet_analyzer_diagnostics_scope = "openFiles"`）

## 3. 验证

- [x] 3.1 执行 `:Lazy sync`，确认 `roslyn.nvim` 插件安装成功，mason 自动下载 Roslyn 服务器
- [x] 3.2 打开一个 `.cs` 文件，确认 fidget.nvim 显示 Roslyn 服务器启动进度
- [x] 3.3 在 `.cs` 文件中触发补全（`i` → 输入几个字母），确认 blink.cmp 显示来自 Roslyn 的补全候选
- [x] 3.4 在符号上按 `gd` 跳转到定义，按 `K` 查看悬停文档，确认正常工作
- [x] 3.5 在含有 `.sln` 或 `.csproj` 的项目目录中打开 nvim，确认 Roslyn 能正确加载整个项目（引用、跨文件跳转可用）
