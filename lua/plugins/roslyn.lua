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
      -- 覆盖 root_dir：多个 sln 时不启动空客户端，而是自动弹出选择菜单
      root_dir = function(bufnr, on_dir)
        local roslyn_config = require("roslyn.config").get()
        if roslyn_config.lock_target and vim.g.roslyn_nvim_selected_solution then
          on_dir(vim.fs.dirname(vim.g.roslyn_nvim_selected_solution))
          return
        end

        local buf_name = vim.api.nvim_buf_get_name(bufnr)
        if buf_name:match("^roslyn%-source%-generated://") then
          local existing_client = vim.lsp.get_clients({ name = "roslyn" })[1]
          if existing_client and existing_client.config.root_dir then
            on_dir(existing_client.config.root_dir)
            return
          end
        end

        local root_dir = require("roslyn.sln.utils").root_dir(bufnr)
        if root_dir then
          on_dir(root_dir)
        else
          -- 多个 sln 且无法自动决定时，不调用 on_dir(nil)，避免启动空客户端
          -- 改为自动弹出 target 选择菜单
          vim.schedule(function()
            vim.cmd("Roslyn target")
          end)
        end
      end,
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
