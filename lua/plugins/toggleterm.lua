return {
    'akinsho/toggleterm.nvim',
    version = "*",
    config = function()
        require("toggleterm").setup({
            -- 可选配置：大小、方向、浮动窗口边框等
            size = 20,
            open_mapping = [[<c-\>]], -- 设置打开/关闭终端的快捷键，如 Ctrl+\
            direction = 'float', -- 'vertical' | 'horizontal' | 'float'
            shell = 'pwsh', -- 使用 PowerShell 7
        })
    end
}