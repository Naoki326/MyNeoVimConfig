return {
  "seblj/roslyn.nvim",
  ft = "cs", -- 只在打开 C# 文件时加载
  dependencies = {
    "mason-org/mason.nvim",
  },
  config = function()
    require("roslyn").setup({
      lock_target = true, -- 记住上次 :Roslyn target 选择的 .sln，避免每次弹窗
      config = {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      },
    })
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    -- LSP 服务器设置（与 roslyn 插件配置分开）
    vim.lsp.config("roslyn", {
      capabilities = capabilities,
      settings = {
        ["csharp|background_analysis"] = {
          dotnet_analyzer_diagnostics_scope = "fullSolution",
          dotnet_compiler_diagnostics_scope = "fullSolution",
        },
        ["csharp|inlay_hints"] = {
          csharp_enable_inlay_hints_for_implicit_object_creation = true,
          csharp_enable_inlay_hints_for_implicit_variable_types = true,
        },
        ["csharp|code_lens"] = {
          dotnet_enable_references_code_lens = true,
        },
      },
    })
  end,
}
