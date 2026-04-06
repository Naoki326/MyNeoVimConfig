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

    vim.lsp.config("roslyn", {
      settings = {
        ["csharp|background_analysis"] = {
          dotnet_analyzer_diagnostics_scope = "openFiles",
          dotnet_compiler_diagnostics_scope = "openFiles",
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

    -- Roslyn 专属快捷键（buffer-local，与 DAP 模式一致）
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("roslyn-keymaps", { clear = true }),
      callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not client or client.name ~= "roslyn" then return end

        local map = function(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = "Roslyn: " .. desc })
        end

        -- 手动选择 .sln 目标
        map("<leader>ct", function()
          vim.cmd("Roslyn target")
        end, "Select Solution Target")

        -- 重启 Roslyn 分析
        map("<leader>cl", function()
          local clients = vim.lsp.get_clients({ name = "roslyn" })
          if #clients == 0 then
            vim.notify("Roslyn: no active client, starting...", vim.log.levels.INFO)
            vim.cmd("LspStart roslyn")
            return
          end
          for _, c in ipairs(clients) do
            c:stop()
          end
          vim.notify("Roslyn: restarting analysis...", vim.log.levels.INFO)
          vim.defer_fn(function()
            vim.cmd("LspStart roslyn")
          end, 500)
        end, "Restart Analysis")
      end,
    })
  end,
}
