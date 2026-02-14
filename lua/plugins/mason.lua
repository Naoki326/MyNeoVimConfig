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
        local success, package = pcall(registry.get_package, "lua-language-server")
        if success and not package:is_installed() then
            package:install()
        end

        -- local nvim_lsp = require("mason-lspconfig.mappings.server").package_to_lspconfig("lua_language-server")
        vim.lsp.config["lua-ls"].setup({})
        vim.cmd("LspStart")
    end
}
