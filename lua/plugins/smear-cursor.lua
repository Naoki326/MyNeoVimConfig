return {
  "sphamba/smear-cursor.nvim",
  event = "VeryLazy",
  opts = {
    -- 光标拖影效果配置
    -- 可以根据需要调整这些选项
    stiffness = 0.7,
    trailing_stiffness = 0.3,
    trailing_exponent = 1,

    smear_between_buffers = true,
    smear_between_neighbor_lines = true,
    scroll_buffer_space = true,
    smear_insert_mode = true,

    cursor_color = "#d3cdc3",
  },
}
