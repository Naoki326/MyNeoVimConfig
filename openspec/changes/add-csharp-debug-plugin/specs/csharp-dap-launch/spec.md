## ADDED Requirements

### Requirement: .NET Console App launch configuration
系统 SHALL 为 `cs` filetype 注册 `coreclr` 类型的 launch configuration，支持调试普通 .NET Console 应用，DLL 路径通过用户输入或自动检测获得。

#### Scenario: 用户启动 Console App 调试
- **WHEN** 用户选择 ".NET: Launch Program" 配置并启动调试
- **THEN** nvim-dap 提示用户输入或确认目标 DLL 路径，然后附加 netcoredbg 启动调试

#### Scenario: DLL 路径预填充
- **WHEN** 调试配置弹出 DLL 路径输入框
- **THEN** 默认值基于当前 `.sln` 所在目录推断的 `bin/Debug/net*/` 输出路径预填充

### Requirement: ASP.NET launch configuration
系统 SHALL 为 `cs` filetype 注册针对 ASP.NET 的 launch configuration，额外传入 `ASPNETCORE_ENVIRONMENT=Development` 环境变量。

#### Scenario: 用户启动 ASP.NET 调试
- **WHEN** 用户选择 ".NET: Launch ASP.NET" 配置并启动调试
- **THEN** netcoredbg 以附带 `ASPNETCORE_ENVIRONMENT=Development` 环境变量的方式启动目标 DLL

#### Scenario: ASP.NET 环境变量注入
- **WHEN** 调试进程启动
- **THEN** 进程环境中包含 `ASPNETCORE_ENVIRONMENT=Development`，其他环境变量继承自父进程

### Requirement: cs_solution.lua 联动推断项目路径
系统 SHALL 调用 `cs_solution.lua` 的 `find_sln()` 方法，将 `.sln` 所在目录作为 launch configuration 的 `cwd` 与 DLL 路径推断基准。

#### Scenario: 存在 .sln 文件时自动定位
- **WHEN** 用户打开一个属于某 .NET 解决方案的 `.cs` 文件
- **THEN** `find_sln()` 返回 `.sln` 路径，launch configuration 的 `cwd` 设为该目录

#### Scenario: 不存在 .sln 文件时回退到 cwd
- **WHEN** 当前文件无法找到上层 `.sln` 文件
- **THEN** launch configuration 的 `cwd` 回退为 `vim.fn.getcwd()`
