return {
    "GustavEikaas/easy-dotnet.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim", },
    config = function ()
        local dotnet = require("easy-dotnet")
        dotnet.setup({
            lsp = {
                enable = false,
                roslynator_enable = true,
                easy_dotnet_analyzer_enable = true,
                auto_refresh_codelens = true,
                config = {},
            },
            debugger = {
            },
        })
    end
}
