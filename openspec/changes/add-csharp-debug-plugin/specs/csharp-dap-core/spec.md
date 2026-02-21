## ADDED Requirements

### Requirement: DAP framework plugin is declared
配置文件 `lua/plugins/dap-cs.lua` 中 SHALL 声明 `mfussenegger/nvim-dap`，并通过 lazy.nvim 懒加载。

#### Scenario: 插件被正确声明
- **WHEN** Neovim 启动并加载 lazy.nvim
- **THEN** `nvim-dap` 出现在插件列表中且未在启动时立即加载

### Requirement: Mason 自动安装 netcoredbg
系统 SHALL 通过 `mason-nvim-dap.nvim` 将 `netcoredbg` 列为 `ensure_installed`，使其在首次启动时自动下载安装。

#### Scenario: 首次启动时安装调试适配器
- **WHEN** 用户首次启动 Neovim（netcoredbg 尚未安装）
- **THEN** Mason 自动下载并安装 `netcoredbg` 到 Mason 数据目录

#### Scenario: 已安装时不重复安装
- **WHEN** `netcoredbg` 已在 Mason 数据目录中存在
- **THEN** Mason 跳过安装，不产生错误

### Requirement: netcoredbg 适配器注册到 nvim-dap
系统 SHALL 在 `dap.adapters.coreclr` 中注册 `netcoredbg` 可执行文件路径，以便 nvim-dap 能够启动调试会话。

#### Scenario: 适配器路径指向 Mason 安装目录
- **WHEN** nvim-dap 初始化时
- **THEN** `dap.adapters.coreclr.executable.command` 解析为 Mason 包路径下的 `netcoredbg` 可执行文件

#### Scenario: 适配器类型正确
- **WHEN** 调试会话启动
- **THEN** 适配器类型为 `executable`，command 和 args 字段完整
