### Requirement: Roslyn LSP 通过 mason 自动安装

配置加载时，mason SHALL 自动检测并安装 Roslyn 语言服务器二进制文件，无需用户手动执行 `:MasonInstall`。

#### Scenario: 首次启动时自动安装
- **WHEN** 用户首次启动 Neovim 且 Roslyn 尚未安装
- **THEN** mason 自动下载并安装 Roslyn 语言服务器到 mason 数据目录

#### Scenario: 已安装时跳过
- **WHEN** Roslyn 已安装
- **THEN** mason 不重复安装，直接启用服务器

---

### Requirement: 单一配置入口

CSharp LSP 的全部配置 SHALL 存在于且仅存在于 `plugins/roslyn.lua` 一个文件中，其他文件不得包含 CSharp LSP 相关配置。

#### Scenario: 无重复的 mason.setup() 调用
- **WHEN** Neovim 启动并加载所有插件
- **THEN** `mason.setup()` 在整个配置中只被调用一次（在 `mason.lua` 中）

#### Scenario: omnisharp 条目不存在
- **WHEN** Neovim 启动
- **THEN** `mason.lua` 的 `lsconfses` 表中不含 `omnisharp` 条目，OmniSharp 不被启动

#### Scenario: easy-dotnet 的 lsp 块被禁用
- **WHEN** Neovim 启动并加载 easy-dotnet.nvim
- **THEN** `easy-dotnet.lua` 中 `lsp.enable` 为 `false`，easy-dotnet 不注入任何 LSP 配置

---

### Requirement: 与 blink.cmp 集成

Roslyn LSP SHALL 使用 `blink.cmp` 的 capabilities，以支持 snippet、label details 等补全增强功能。

#### Scenario: 补全候选包含代码片段
- **WHEN** 用户在 C# 文件中触发补全
- **THEN** 补全候选由 Roslyn LSP 提供，并经过 blink.cmp 的 capabilities 过滤与渲染

---

### Requirement: 项目文件自动检测

Roslyn LSP SHALL 自动检测项目根目录下的 `.sln` 或 `.csproj` 文件，并以此为工作空间根目录启动。

#### Scenario: 存在 .sln 文件
- **WHEN** 用户在含有 `.sln` 文件的目录下打开 Neovim，并打开一个 `.cs` 文件
- **THEN** Roslyn LSP 以该 `.sln` 所在目录为根启动，加载整个解决方案

#### Scenario: 仅存在 .csproj 文件
- **WHEN** 用户在含有 `.csproj` 文件的目录下打开 Neovim
- **THEN** Roslyn LSP 以该 `.csproj` 所在目录为根启动

---

### Requirement: 标准 LSP 功能可用

在 C# 文件中，以下 LSP 功能 SHALL 通过现有 `mason.lua` 的 `LspAttach` 快捷键正常工作。

#### Scenario: 跳转到定义
- **WHEN** 用户在 C# 符号上按 `gd`
- **THEN** Telescope 打开并显示该符号的定义位置

#### Scenario: 悬停文档
- **WHEN** 用户在 C# 符号上按 `K`
- **THEN** 浮动窗口显示该符号的文档说明

#### Scenario: 代码操作
- **WHEN** 用户按 `<leader>ca`
- **THEN** 显示 Roslyn 提供的 C# 代码操作（如 using 导入、重构等）

#### Scenario: 重命名
- **WHEN** 用户按 `<leader>cr`
- **THEN** 可对 C# 符号进行跨文件重命名
