return {
  -- LSP 进度显示
  {
    "j-hui/fidget.nvim",
    opts = {
      notification = {
        window = {
          winblend = 0, -- 透明度
          relative = "editor",
        },
      },
      progress = {
        display = {
          done_icon = "✓", -- 完成图标
          progress_icon = { pattern = "dots", period = 1 }, -- 进度动画
        },
      },
    },
  },
}
