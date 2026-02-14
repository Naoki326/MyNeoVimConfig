return {
  "folke/noice.nvim",
  event = "VeryLazy",
  opts = {
    -- 你的自定义配置
    cmdline = {
      enabled = true, -- 确保命令行增强已启用
      view = "cmdline_popup", -- 使用弹出窗口风格
    },
    -- 其他配置...
  },
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  }
}