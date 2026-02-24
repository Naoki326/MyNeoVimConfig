### Requirement: DAP framework plugin is declared

配置文件 `lua/plugins/dap-cs.lua` 中 SHALL 声明 `mfussenegger/nvim-dap`，并通过 lazy.nvim 懒加载。

#### Scenario: 插件被正确声明
- **WHEN** Neovim 启动并加载 lazy.nvim
- **THEN** `nvim-dap` 出现在插件列表中且未在启动时立即加载

---

### Requirement: netcoredbg 可通过 Mason 安装

系统 SHALL 确保 `netcoredbg` 可通过 Mason 安装，未安装时给出明确提示。

#### Scenario: netcoredbg 已安装时正常注册适配器
- **WHEN** 用户已通过 Mason 安装 `netcoredbg`
- **THEN** 适配器自动注册，无需用户额外操作

#### Scenario: netcoredbg 未安装时给出提示
- **WHEN** 用户未安装 `netcoredbg`
- **THEN** Neovim 显示 WARN 通知，告知用户运行 `:MasonInstall netcoredbg`

---

### Requirement: netcoredbg 适配器注册到 nvim-dap

系统 SHALL 在 `dap.adapters.coreclr` 中注册 `netcoredbg` 可执行文件路径，以便 nvim-dap 能够启动调试会话。

#### Scenario: 适配器路径指向 Mason 安装目录
- **WHEN** nvim-dap 初始化时
- **THEN** `dap.adapters.coreclr.executable.command` 解析为 Mason 包路径下的 `netcoredbg` 可执行文件

#### Scenario: 适配器类型正确
- **WHEN** 调试会话启动
- **THEN** 适配器类型为 `executable`，command 和 args 字段完整
