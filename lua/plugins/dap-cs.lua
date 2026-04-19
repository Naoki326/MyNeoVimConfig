-- DAP 插件声明（仅注册插件，初始化逻辑在 lua/core/dap.lua）
return {
  { "mfussenegger/nvim-dap",           lazy = true },
  { "nvim-neotest/nvim-nio",           lazy = true },
  {
    "rcarriga/nvim-dap-ui",
    lazy = true,
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    lazy = true,
    dependencies = { "mfussenegger/nvim-dap", "nvim-treesitter/nvim-treesitter" },
  },
  -- telescope-dap / telescope-ui-select 已移除（统一使用 snacks.picker）
}
