# Fix: Roslyn sln 自动搜索不准确 & 多文件编辑后不重新分析

## 变更概述

roslyn.nvim 插件的两个问题修复：

1. sln 自动搜索不准确 → 改为快捷键手动触发 `:Roslyn target` 选择
2. 多文件编辑后 roslyn 不重新分析 → 添加手动重启 roslyn 的快捷键

## 设计动机

- 项目中存在 `lua/cs_solution.lua` 的 `find_sln()` 通过向上遍历 6 层目录搜索 .sln，但 roslyn.nvim 内部有自己的 sln 搜索逻辑（通过 `roslyn.sln.utils`），两者行为不一致
- roslyn 的自动 sln 搜索在有多个 .sln 或嵌套项目结构时容易选错
- `lock_target = true` 已启用，只要用户手动选过一次就会记住，所以关键是提供手动触发的入口
- roslyn 有时在大量编辑后不重新分析，需要手动重启

## 接口契约

### 新增快捷键（buffer-local，仅在 roslyn attach 的 C# buffer 生效）

| 快捷键 | 功能 | 实现方式 |
|--------|------|----------|
| `<leader>cT` | 选择解决方案目标 (.sln) | `vim.cmd("Roslyn target")` |
| `<leader>cR` | 重启 Roslyn 分析 | 停止所有 roslyn clients → 延迟 500ms → LspStart roslyn |

### 受影响文件

| 文件 | 变更类型 | 说明 |
|------|----------|------|
| `lua/plugins/roslyn.lua` | 修改 | 添加 LspAttach autocmd + 快捷键 + restart_roslyn 函数，删除注释掉的 init 块 |
| `lua/plugins/whichkey.lua` | 修改 | 在 `<leader>c` code group 下添加 cT/cR 描述 |

### 不受影响

- `lua/cs_solution.lua` — neo-tree 的 sln 解析逻辑不变
- `lua/plugins/neo-tree.lua` — neo-tree 集成不变
- `lua/core/dap.lua` — DAP 集成不变
- `lua/core/keymap.lua` — 全局快捷键不变

## 边界情况

1. **无 roslyn client 时按 `<leader>cR`**: 显示 "no active client" 警告，尝试 `LspStart roslyn`
2. **多个 roslyn client**: 全部停止后统一重启
3. **`<leader>cT` 在 roslyn 未 attach 时**: `:Roslyn target` 命令在插件加载后即可用（ft=cs 时加载），所以只要在 .cs buffer 就能用
4. **lock_target 已保存**: 如果用户之前选过 target，`<leader>cT` 会预选上次的选择，用户可以直接确认或切换
5. **重启期间编辑**: `client:stop()` 是异步的，重启有 500ms 延迟缓冲

## 约束

- 快捷键使用 buffer-local 模式（与 DAP 快捷键在 dap.lua 中的模式一致）
- 不引入新的插件依赖
- 不修改 roslyn.nvim 的 root_dir 逻辑（注释掉的 init 块直接删除）
