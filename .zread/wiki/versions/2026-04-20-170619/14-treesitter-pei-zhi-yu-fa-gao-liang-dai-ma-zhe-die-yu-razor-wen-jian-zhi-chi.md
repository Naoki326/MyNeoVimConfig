Treesitter 是 Neovim 内置的增量式语法解析框架，它通过构建精确的语法树（syntax tree）为编辑器提供语法高亮、缩进计算和代码折叠三大核心能力。本配置基于 `nvim-treesitter` 插件的 **main 分支新 API**，采用手动安装 + 按需激活的策略，在 9 种文件类型上启用了完整的 Treesitter 功能。作为 .NET 开发者，配置中特别加入了 **Razor 文件**（`.razor` / `.cshtml`）的解析器支持——这是 Neovim 社区中较为少见但极具价值的配置，让你在 Blazor 项目中也能获得精确的语法高亮和结构化折叠。

Sources: [treesitter.lua](lua/plugins/treesitter.lua#L1-L48)

## 整体架构：从解析器到编辑器能力

在深入各模块之前，先理解 Treesitter 在本配置中的角色边界。下图展示了 Treesitter 与相关插件之间的依赖关系和数据流向：

```mermaid
graph TD
    subgraph "核心插件层"
        TS["nvim-treesitter<br/>(main 分支新 API)"]
    end

    subgraph "解析器安装"
        TS -->|install()| Parsers["10 个语言解析器<br/>c, lua, vim, vimdoc, query<br/>javascript, python, c_sharp<br/>markdown, razor"]
    end

    subgraph "编辑器能力激活（FileType autocmd）"
        Parsers -->|vim.treesitter.start| HL["语法高亮"]
        Parsers -->|indentexpr| IND["智能缩进"]
        Parsers -->|foldexpr + foldmethod| FD["代码折叠表达式"]
    end

    subgraph "下游消费者插件"
        FD -->|"foldexpr 提供"| UFO["nvim-ufo<br/>折叠 UI 增强"]
        TS -->|"语法树查询"| RAINBOW["rainbow-delimiters<br/>彩虹括号"]
        TS -->|"语法树查询"| RMD["render-markdown<br/>Markdown 渲染"]
    end

    subgraph "文件类型映射"
        FTM["vim.filetype.add<br/>.razor → razor<br/>.cshtml → razor"]
        FTM -->|触发 FileType 事件| Parsers
    end
```

**架构要点**：Treesitter 在本配置中扮演"基础设施"角色——它自身不直接提供用户界面，而是通过语法树为下游插件（nvim-ufo 折叠 UI、rainbow-delimiters 彩虹括号、render-markdown Markdown 渲染）提供结构化数据。`FileType` 自动命令是整个链路的枢纽，它将解析器安装与缓冲区级功能激活连接起来。

Sources: [treesitter.lua](lua/plugins/treesitter.lua#L1-L48), [nvim-ufo.lua](lua/plugins/nvim-ufo.lua#L1-L24), [rainebow.lua](lua/plugins/rainebow.lua#L1-L5), [render-markdown.lua](lua/plugins/render-markdown.lua#L1-L9)

## 插件声明与加载策略

```lua
return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",       -- 使用新 API 分支
    lazy = false,          -- 启动时立即加载
    build = ":TSUpdate",   -- 首次安装时更新解析器
    config = function()    -- 自定义配置
        ...
    end,
}
```

这里有几个值得关注的决策：

| 配置项 | 值 | 设计意图 |
|--------|-----|----------|
| `branch` | `"main"` | 使用 nvim-treesitter 的**新 API 分支**。传统的 `master` 分支使用 `ensure_installed` + `setup()` 模式，而 `main` 分支采用 `install()` + 原生 `vim.treesitter` API，更轻量、与 Neovim 内置 API 对齐 |
| `lazy` | `false` | Treesitter 是编辑器基础设施，不采用懒加载。多个下游插件依赖其语法树，延迟加载可能导致首次打开文件时高亮缺失 |
| `build` | `":TSUpdate"` | 懒加载框架在插件安装/更新后自动执行此命令，确保解析器编译到最新版本 |

**新旧 API 对比**：如果你查阅过其他 Neovim 配置教程，可能会看到类似 `require("nvim-treesitter.configs").setup({ highlight = { enable = true } })` 的写法——那是 `master` 分支的旧模式。本配置使用的 `main` 分支 API 更符合 Neovim 原生设计理念：解析器安装与功能激活是**分离的两个步骤**，由你手动编排。

Sources: [treesitter.lua](lua/plugins/treesitter.lua#L1-L6)

## 解析器安装：精确控制语言范围

```lua
require("nvim-treesitter").install({
    "c", "lua", "vim", "vimdoc", "query",
    "javascript", "python",
    "c_sharp", "markdown", "razor",
})
```

`install()` 函数接收解析器名称列表，自动从 GitHub 下载并编译对应的 C 语言解析器动态库。本配置安装的 10 个解析器可以按用途分为四个类别：

| 类别 | 解析器 | 用途说明 |
|------|--------|----------|
| **Neovim 自身** | `c`, `lua`, `vim`, `vimdoc`, `query` | 编辑 Lua 配置文件、Vim 脚本、帮助文档和 Treesitter 查询文件时获得高亮和结构理解 |
| **通用语言** | `javascript`, `python` | 覆盖项目中可能涉及的脚本语言和前端代码 |
| **.NET 核心** | `c_sharp` | C# 语法高亮和结构化折叠的基石 |
| **标记与模板** | `markdown`, `razor` | Markdown 高亮（render-markdown 插件依赖）；Razor 是 Blazor 和 ASP.NET MVC 视图的模板语言 |

对于 C#/.NET 开发者而言，**`c_sharp` + `razor`** 组合是关键。`c_sharp` 解析器提供精确的类、方法、属性等语法节点识别；`razor` 解析器则能理解 `@code`、`@inject`、`@page` 等 Razor 指令的语法结构，让你在 `.razor` 文件中获得完整的语法高亮。

> **注意**：`install()` 是幂等操作——如果解析器已经安装且版本匹配，不会重复下载。但当你更新 Neovim 版本后，可能需要手动执行 `:TSUpdate` 重新编译所有解析器以确保 ABI 兼容。

Sources: [treesitter.lua](lua/plugins/treesitter.lua#L7-L18)

## Razor 文件类型映射

```lua
vim.filetype.add({
    extension = {
        razor = "razor",
        cshtml = "razor",
    },
})
```

这段代码解决了一个关键问题：**让 Neovim 正确识别 Razor 文件的类型**。默认情况下，Neovim 不知道如何处理 `.razor`（Blazor 组件）和 `.cshtml`（ASP.NET MVC 视图）扩展名。通过 `vim.filetype.add()` 将这两种扩展名统一映射到 `razor` 文件类型，后续的 `FileType` 自动命令才能正确触发 Treesitter 激活。

**设计决策**：`.razor` 和 `.cshtml` 被映射到**同一个** `razor` 文件类型，因为它们的语法结构基本一致——都混合了 HTML 标记和 C# 代码块，只是用途不同（Blazor 组件 vs MVC 视图）。Treesitter 的 `razor` 解析器能同时处理这两种格式。

文件类型映射的执行时序至关重要——它必须**先于** `FileType` 自动命令注册。在本配置中，由于两者都在同一个 `config` 函数内顺序执行，映射一定在自动命令注册之前生效，不会有时序问题。

Sources: [treesitter.lua](lua/plugins/treesitter.lua#L20-L25)

## FileType 自动命令：三合一的缓冲区激活

```lua
vim.api.nvim_create_autocmd("FileType", {
    pattern = {
        "c", "lua", "vim", "help", "query",
        "javascript", "python", "cs", "markdown", "razor",
    },
    callback = function(args)
        vim.treesitter.start()                                          -- ① 启动高亮
        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"  -- ② 智能缩进
        vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"       -- ③ 折叠表达式
        vim.wo[0][0].foldmethod = "expr"                                -- ③ 启用表达式折叠
    end,
})
```

这是整个 Treesitter 配置的核心——一个 `FileType` 自动命令在目标文件类型打开时，为当前缓冲区激活三项能力：

### ① 语法高亮：`vim.treesitter.start()`

调用 Neovim 内置的 `vim.treesitter.start()` 函数，为当前缓冲区附加 Treesitter 高亮器。高亮器会根据解析器生成的语法树节点，将 `@function`、`@keyword`、`@string` 等语义捕获组映射到对应的 Neovim 高亮组（highlight group）。主题插件（如 [tokyonight](18-jie-mian-mei-hua-xi-tong-tokyonight-zhu-ti-noice-ming-ling-xing-lualine-zhuang-tai-lan)）则为这些高亮组定义颜色。

### ② 智能缩进：`indentexpr`

将缓冲区的 `indentexpr` 选项设置为 nvim-treesitter 提供的缩进函数。当你在新行按 `<Enter>` 或使用 `==` 缩进操作时，Neovim 会调用此函数根据语法树计算正确的缩进级别。例如，C# 的大括号内代码会自动增加一级缩进。

### ③ 代码折叠：`foldexpr` + `foldmethod`

将窗口的 `foldmethod` 设为 `"expr"`，`foldexpr` 设为 Treesitter 的折叠表达式函数。Treesitter 会根据语法树识别函数、类、命名空间等结构节点，将其作为折叠边界。注意 `pattern` 列表中使用 `"help"` 而非 `"vimdoc"`——这是因为 Vim/Neovim 的帮助文件 `filetype` 值是 `help`，而非解析器名称 `vimdoc`。同样，C# 文件的 `filetype` 值是 `"cs"` 而非 `"c_sharp"`。

**对比安装列表与激活列表**，你会发现它们并非完全一一对应：

| 解析器名（install） | 文件类型（autocmd pattern） | 说明 |
|---------------------|---------------------------|------|
| `vimdoc` | `help` | 解析器名与 filetype 值不同 |
| `c_sharp` | `cs` | 解析器名与 filetype 值不同 |
| `query` | `query` | 直接对应 |
| `razor` | `razor` | 直接对应 |

Sources: [treesitter.lua](lua/plugins/treesitter.lua#L27-L46)

## 与 nvim-ufo 的协同关系

Treesitter 提供的 `foldexpr` 定义了**折叠边界在哪里**（哪些语法节点可以折叠），而 [nvim-ufo](20-dai-ma-zhe-die-fang-an-nvim-ufo-zhe-die-biao-da-shi) 则提供了**折叠的呈现方式**——包括折叠预览、美观的折叠列符号、以及更智能的 `zR`/`zM` 全局操作。

两者的协作链路如下：

```
Treesitter foldexpr → 识别函数/类/命名空间等节点 → 生成折叠信息
                                                        ↓
nvim-ufo setup() → 读取 foldexpr 结果 → 渲染折叠列 + 折叠预览 + 快捷键增强
```

在本配置中，nvim-ufo 的 `setup()` 使用默认 provider 策略（主用 `lsp`，备用 `indent`），但由于 Treesitter 已经通过 `foldexpr` 直接提供了折叠信息，nvim-ufo 的 provider 选择器在 Treesitter 已激活的缓冲区中实际会**叠加使用**这些信息。同时，nvim-ufo 还设置了 `foldcolumn = "1"` 和 `foldlevel = 99` 等全局选项，确保折叠功能在视觉和交互层面都处于就绪状态。

Sources: [treesitter.lua](lua/plugins/treesitter.lua#L43-L44), [nvim-ufo.lua](lua/plugins/nvim-ufo.lua#L6-L22)

## 下游依赖插件概览

Treesitter 作为基础语法设施，被多个插件声明为依赖项：

| 插件 | 依赖方式 | 对 Treesitter 的使用 |
|------|----------|---------------------|
| **rainbow-delimiters** | `dependencies = { "nvim-treesitter/nvim-treesitter" }` | 利用 Treesitter 语法树识别嵌套的括号/方括号/花括号对，为不同层级着色 |
| **render-markdown** | `dependencies = { 'nvim-treesitter/nvim-treesitter', ... }` | 使用 `markdown` 解析器理解 Markdown 文档结构，将标题、代码块、列表等渲染为可视化元素 |

这些插件通过 `lazy = false` 或各自的懒加载事件触发加载。由于 Treesitter 本身也设为 `lazy = false`，加载顺序由 lazy.nvim 自动保证——Treesitter 一定在其依赖者之前完成初始化。

Sources: [rainebow.lua](lua/plugins/rainebow.lua#L1-L5), [render-markdown.lua](lua/plugins/render-markdown.lua#L1-L9)

## 已安装解析器的语言对照表

为方便维护和扩展，以下是本配置所有解析器的完整对照：

| 解析器名 | 文件类型 | 主要用途 | 对应文件扩展名（常见） |
|----------|----------|----------|----------------------|
| `c` | `c` | C 语言高亮与折叠 | `.c`, `.h` |
| `lua` | `lua` | Lua 脚本高亮与折叠 | `.lua` |
| `vim` | `vim` | Vim 脚本高亮 | `.vim` |
| `vimdoc` | `help` | Vim 帮助文档高亮 | `*.txt`（Vim help 格式） |
| `query` | `query` | Treesitter 查询文件高亮 | `.scm` |
| `javascript` | `javascript` | JavaScript 高亮 | `.js`, `.mjs` |
| `python` | `python` | Python 高亮 | `.py` |
| `c_sharp` | `cs` | C# 高亮与折叠 | `.cs` |
| `markdown` | `markdown` | Markdown 结构化渲染 | `.md`, `.mdx` |
| `razor` | `razor` | Razor 模板高亮 | `.razor`, `.cshtml` |

如果你需要添加新语言支持，只需在 `install()` 列表和 `FileType` pattern 列表中同时添加对应名称即可。注意区分解析器名称（如 `c_sharp`）和文件类型名称（如 `cs`），可通过 `:echo &filetype` 命令确认当前缓冲区的文件类型值。

Sources: [treesitter.lua](lua/plugins/treesitter.lua#L7-L46)

## 常见问题与故障排除

| 症状 | 可能原因 | 解决方法 |
|------|----------|----------|
| C# 文件无高亮 | `c_sharp` 解析器未安装 | 执行 `:TSInstall c_sharp`，然后重新打开文件 |
| `.razor` 文件显示为纯文本 | 文件类型未正确识别 | 检查 `:echo &filetype`，应输出 `razor`；若为空，确认配置已正确加载 |
| 折叠功能不工作 | `foldmethod` 未设置为 `expr` | 检查 `:set foldmethod?`，确认输出为 `foldmethod=expr`；若为 `manual`，可能是其他插件覆盖了设置 |
| 高亮显示异常（锯齿状更新） | 解析器与 Neovim 版本不兼容 | 执行 `:TSUpdate` 重新编译所有解析器 |
| `:TSUpdate` 报错找不到编译器 | 系统缺少 C 编译器 | 安装 Visual Studio Build Tools 或 MinGW，确保 `cc` / `gcc` 在 PATH 中 |

Sources: [treesitter.lua](lua/plugins/treesitter.lua#L1-L48)

## 延伸阅读

- [代码折叠方案：nvim-ufo 与 Treesitter 折叠表达式](20-dai-ma-zhe-die-fang-an-nvim-ufo-yu-treesitter-zhe-die-biao-da-shi) — 深入了解 nvim-ufo 如何利用 Treesitter foldexpr 提供增强的折叠 UI
- [界面美化系统：tokyonight 主题、noice 命令行、lualine 状态栏](18-jie-mian-mei-hua-xi-tong-tokyonight-zhu-ti-noice-ming-ling-xing-lualine-zhuang-tai-lan) — 了解主题如何定义 Treesitter 高亮组的颜色
- [双模块分层设计：core 基础层与 plugins 扩展层](4-shuang-mo-kuai-fen-ceng-she-ji-core-ji-chu-ceng-yu-plugins-kuo-zhan-ceng) — 理解 Treesitter 配置在整体架构中的定位