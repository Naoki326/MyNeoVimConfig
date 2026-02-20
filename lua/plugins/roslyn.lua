return {
  "seblj/roslyn.nvim",
  ft = "cs", -- 只在打开 C# 文件时加载
  dependencies = {
    "mason-org/mason.nvim",
  },
  config = function()
    require("roslyn").setup({
      config = {
        -- 集成 blink.cmp 的补全能力（snippet、label details 等）
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      },
    })

    -- LSP 服务器设置（与 roslyn 插件配置分开）
    vim.lsp.config("roslyn", {
      settings = {
        -- 仅分析当前打开的文件，减少 CPU/内存占用
        -- 如果需要全项目分析，改为 "fullSolution"
        ["csharp|background_analysis"] = {
          dotnet_analyzer_diagnostics_scope = "openFiles",
          dotnet_compiler_diagnostics_scope = "openFiles",
        },
      },
    })
  end,
}
