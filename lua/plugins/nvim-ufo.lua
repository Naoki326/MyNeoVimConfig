return {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" }, -- 必需的依赖
    version = false, -- 建议运行最新版本
    config = function()
        -- 1. 设置必要的 Neovim 原生选项
        vim.o.foldcolumn = "1"          -- 显示左侧的折叠列，0 为不显示
        vim.o.foldlevel = 99             -- 使用 ufo 需要设置一个较大的值，让所有折叠默认打开
        vim.o.foldlevelstart = 99        -- 文件打开时，折叠级别
        vim.o.foldenable = true          -- 启用折叠

        -- 2. （可选）美化折叠列的显示符号，需要 Nerd Font 支持
        vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]

        -- 3. 重新映射 zR 和 zM，这是使用 ufo provider 的关键步骤
        --    默认的 zR/zM 会改变 foldlevel，ufo 提供的版本则不会，体验更好
        vim.keymap.set("n", "zR", require("ufo").openAllFolds)
        vim.keymap.set("n", "zM", require("ufo").closeAllFolds)

        -- 4. 初始化 ufo（使用默认配置，provider 选择器为 nil，后续可以覆盖）
        --    默认的 provider 策略是：主用 'lsp'，备用 'indent'
        require("ufo").setup()
    end,
}
