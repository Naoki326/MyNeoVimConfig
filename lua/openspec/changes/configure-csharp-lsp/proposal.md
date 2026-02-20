## Why

现有的 CSharp LSP 配置由多个互相冲突的片段拼凑而成：`csharp.lua` 使用 `csharp.nvim` 插件包装 OmniSharp 并在内部重复调用 `mason.setup()`，`mason.lua` 同时也配置了 OmniSharp，导致 LSP 服务器被两处初始化。`lsp.lua` 第一行直接返回空表被完全禁用。整体配置无法理解、无法维护，出问题时不知道从何入手。

## What Changes

- 删除 `plugins/csharp.lua`（移除 `iabdelkareem/csharp.nvim` 及其所有依赖 `mfussenegger/nvim-dap`、`Tastyep/structlog.nvim` 的 C# 相关部分）
- 删除 `plugins/mason.lua` 中重复的 `["omnisharp"] = {}` 条目
- 删除 `plugins/easy-dotnet.lua` 中的 `lsp` 配置块（保留其他 .NET 工具功能）
- 删除已死的 `plugins/lsp.lua`
- 在 `mason.lua` 中用已有的统一模式重新配置 CSharp LSP，每个选项附注释说明作用

## Capabilities

### New Capabilities

- `csharp-lsp-config`: 通过 mason + nvim-lspconfig 的统一模式配置 CSharp 语言服务器，单一入口，每个配置项有注释说明

### Modified Capabilities

（无，mason.lua 的通用 LSP 模式不变，仅新增 CSharp 条目）

## Impact

| 文件 | 操作 | 说明 |
|------|------|------|
| `plugins/csharp.lua` | 删除 | 完全移除 csharp.nvim 及其 mason.setup() 调用 |
| `plugins/mason.lua` | 修改 | 移除 omnisharp 重复条目，新增干净的 CSharp LSP 配置 |
| `plugins/easy-dotnet.lua` | 修改 | 移除 `lsp` 配置块，只保留 .NET 工具功能 |
| `plugins/lsp.lua` | 删除 | 死代码，第一行就 return {} |

**依赖变化：**
- 移除：`iabdelkareem/csharp.nvim`、`Tastyep/structlog.nvim`（仅被 csharp.nvim 使用）
- 保留：`mason-org/mason.nvim`、`mason-org/mason-lspconfig.nvim`、`neovim/nvim-lspconfig`
- LSP 服务器：**Roslyn LSP**（微软官方，与 VS Code C# 扩展同一个服务器）
