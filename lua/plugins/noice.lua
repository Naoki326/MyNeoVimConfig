return {
  "folke/noice.nvim",
  event = "VeryLazy",
  opts = {
    -- 你的自定义配置-- 设置窗口位置（可按需调整）
	position = {
	  row = "10%",   -- 例如距离顶部 10% 处
	  col = "50%",
	},
    cmdline = {
      enabled = true, -- 确保命令行增强已启用
      view = "cmdline_popup", -- 使用弹出窗口风格
    },
    -- 其他配置...
	-- ✨ 核心：将 zindex 设为较高值，确保始终在上层
	zindex = 200,
  },
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  }
}