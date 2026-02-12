-- 通用 LSP 配置（不包括 C#，C# 由 csharp.nvim 管理）
local servers = {
  "vtsls", -- TypeScript/JavaScript
  "lua_ls", -- Lua
  "html", -- HTML
  "cssls", -- CSS
}

return {
  { -- LSP Configuration & Plugins
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufNewFile", "BufWritePre" },
    dependencies = {
      { "mason-org/mason.nvim", config = true },
      "mason-org/mason-lspconfig.nvim",
      { "j-hui/fidget.nvim", event = "LspAttach", opts = {} },
      { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
    },
    config = function()
      -- LSP 快捷键配置
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user-lsp-attach", { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          -- 跳转快捷键
          map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
          map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
          map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
          map("gy", require("telescope.builtin").lsp_type_definitions, "Goto T[y]pe Definition")
          map("<leader>cs", require("telescope.builtin").lsp_document_symbols, "Document [S]ymbols")

          -- 代码操作
          map("<leader>cr", vim.lsp.buf.rename, "[C]ode [R]ename")
          map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
          map("K", vim.lsp.buf.hover, "Hover Documentation")
          map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
        end,
      })

      -- LSP capabilities（使用 blink.cmp）
      local capabilities = vim.lsp.protocol.make_client_capabilities()

      -- 如果使用 blink.cmp，获取其 capabilities
      local ok, blink = pcall(require, "blink.cmp")
      if ok then
        capabilities = vim.tbl_deep_extend("force", capabilities, blink.get_lsp_capabilities())
      end

      require("mason").setup()

      local mason_lspconfig = require("mason-lspconfig")
      mason_lspconfig.setup({
        ensure_installed = servers,
        automatic_installation = true,
      })

      local lsconfses = {
        lua_ls = {
          capabilities = capabilities,
          settings = {
            Lua = {
              completion = {
                callSnippet = "Replace",
              },
              diagnostics = {
                globals = { "vim" },
              },
            },
          },
        },
        vtsls = {
          capabilities = capabilities,
        },
        html = {
          capabilities = capabilities,
        },
        cssls = {
          capabilities = capabilities,
        },
      }

      for name, config in pairs(lsconfses) do
        vim.lsp.config(name, config)
        vim.lsp.enable(name)
      end
    end,
  },
}
