local lsconfses = {
  ["lua-language-server"] = {
    --capabilities = capabilities,
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
--vtsls = {
--  capabilities = capabilities,
--},
--html = {
--  capabilities = capabilities,
--},
--cssls = {
--  capabilities = capabilities,
--},
}

return {
    "mason-org/mason.nvim",
    event = "VeryLazy",
    dependencies = {
        "neovim/nvim-lspconfig",
        "mason-org/mason-lspconfig.nvim",
    },
    opts = {},
    config = function (_, opts)
        require("mason").setup(opts)
        local registry = require("mason-registry")

        local function setup(name, config)
            local success, package = pcall(registry.get_package, name)
            if success and not package:is_installed() then
                package:install()
            end

            local lsp = require("mason-lspconfig").get_mappings().package_to_lspconfig[name]
            vim.lsp.config(lsp, config)
            vim.lsp.enable(lsp)
        end
        for name, config in pairs(lsconfses) do
            setup(name, config)
        end
        --vim.cmd("LspStart")
        vim.diagnostic.config({
            virtual_text = true,
            -- virtual_lines = true,
            update_in_insert = true
        })

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
    end
}
