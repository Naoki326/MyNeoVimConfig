return {
  "olimorris/persisted.nvim",
  lazy = false,
  opts = {
    -- 手动保存模式（不自动保存）
    autostart = false,
    -- 不自动加载，手动恢复
    autoload = false,
    -- 保存 tab 页布局（通过 sessionoptions 的 tabpages 实现）
    -- 见下方 init 里的 sessionoptions 设置
    -- 可选：按 git 分支区分 session
    -- use_git_branch = true,
    -- 可选：排除目录
    -- ignored_dirs = { "~/", "~/Downloads", "/" },
  },
  init = function()
    -- 关键：让 session 保存 tab 页布局
    -- buffers=保存 buffer 列表, tabpages=保存 tab 布局, winsize=窗口大小
    vim.o.sessionoptions = "buffers,curdir,folds,globals,tabpages,winpos,winsize"
  end,
}
