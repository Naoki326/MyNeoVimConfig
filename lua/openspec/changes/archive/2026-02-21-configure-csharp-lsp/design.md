## Context

当前配置存在以下技术问题：

- `plugins/csharp.lua` 在自己的 `config` 函数里调用 `require("mason").setup()`，而 `mason.lua` 也会调用一次，mason 被初始化两次
- `mason.lua` 的 `lsconfses` 表里有 `["omnisharp"] = {}`，`csharp.lua` 也配置了 omnisharp，导致 OmniSharp 服务器被两处启动
- `lsp.lua` 第一行是 `if true then return {} end`，属于完全无效的死代码
- `easy-dotnet.lua` 开启了 `lsp.enable = true` + `roslynator_enable = true`，又添加了一层 LSP 相关逻辑

目标：单一、可理解的 CSharp LSP 入口。

## Goals / Non-Goals

**Goals:**

- 删除所有冲突的 CSharp LSP 配置，只保留一个来源
- 使用 Roslyn LSP（官方微软 C# 语言服务器）
- 每个配置项有注释，出问题时知道从哪里改
- 与现有 `blink.cmp`、`fidget.nvim`、`telescope.nvim` 集成保持不变

**Non-Goals:**

- 不改动 DAP（调试）配置
- 不改动非 C# 语言的 LSP 配置（lua_ls 等在 mason.lua 中保持不动）
- 不重新设计 mason.lua 的通用结构

## Decisions

### 决策 1：使用 `seblj/roslyn.nvim` 而非直接 mason + lspconfig

**选择**：新建 `plugins/roslyn.lua`，使用 `seblj/roslyn.nvim` 插件。

**原因**：Roslyn LSP 不像普通 LSP 那样通过标准 stdio 通信，它使用命名管道（named pipe）。`seblj/roslyn.nvim` 专门处理这个通信细节、解决方案文件（`.sln`）自动检测、以及通过 mason 管理服务器二进制文件。如果直接用 `vim.lsp.config` + `vim.lsp.enable`（mason.lua 现有模式），需要手动处理这些 Roslyn 特有的通信问题，容易出错。

**备选方案**：继续用 OmniSharp via mason.lua 现有模式。放弃原因：OmniSharp 已不再是微软主推方向，Roslyn LSP 是与 VS Code C# 扩展相同的服务器，功能更全、问题更少。

**备选方案 2**：`csharp-language-server`（csharp-ls）。放弃原因：功能较少，社区生态不如 Roslyn。

### 决策 2：CSharp 配置独立成 `plugins/roslyn.lua`，不合并入 `mason.lua`

**选择**：新建独立文件 `plugins/roslyn.lua`。

**原因**：`seblj/roslyn.nvim` 本身是一个 lazy.nvim 插件，有自己的 `dependencies`、`config` 函数。把它塞进 mason.lua 的 `lsconfses` 表不符合这个插件的使用方式。独立文件更清晰，也与现有 `plugins/` 目录下各插件一文件一配置的风格一致。

### 决策 3：easy-dotnet.nvim 保留，但禁用其 `lsp` 配置块

**选择**：`easy-dotnet.lua` 中将 `lsp.enable` 改为 `false`。

**原因**：easy-dotnet.nvim 的 `lsp.enable = true` 会向 LSP 注入 Roslynator 分析器配置。在 Roslyn LSP 稳定运行之前，这一层额外配置会增加调试难度。待 Roslyn 基础配置确认工作正常后，可以单独决定是否重新启用 Roslynator。

### 决策 4：从 `mason.lua` 移除 `["omnisharp"] = {}` 条目

**选择**：直接删除该条目。

**原因**：OmniSharp 将由 Roslyn LSP 完全替代，不再需要。mason-registry 会在下次启动时自动跳过未配置的包。

## Risks / Trade-offs

| 风险 | 缓解措施 |
|------|---------|
| Roslyn LSP 首次需要下载服务器二进制（~100MB） | mason 自动处理，仅首次，后续无需重新下载 |
| `seblj/roslyn.nvim` 需要 .sln 或 .csproj 文件才能正确启动 | 这是正常行为，在项目根目录打开 nvim 即可 |
| easy-dotnet.nvim 的 Roslynator 功能暂时关闭 | 影响有限，基础代码分析由 Roslyn LSP 本身提供，Roslynator 是可选增强 |

## Migration Plan

1. 删除 `plugins/csharp.lua`
2. 删除 `plugins/lsp.lua`
3. 修改 `plugins/mason.lua`：移除 `["omnisharp"] = {}` 条目
4. 修改 `plugins/easy-dotnet.lua`：将 `lsp.enable` 改为 `false`
5. 新建 `plugins/roslyn.lua`：配置 `seblj/roslyn.nvim`

**回滚**：git 还原上述文件，重新运行 `:Lazy sync` 即可恢复 OmniSharp。

## Open Questions

- `seblj/roslyn.nvim` 的具体 mason 包名：在 specs 阶段确认（预计为 `roslyn`）
- 是否需要 `.editorconfig` 支持：Roslyn LSP 原生支持，无需额外配置
