vim.g.mapleader = " "

local map = vim.keymap.set
map({ "n", "i" }, "<C-z>", "<Cmd>undo<CR>", { silent = true })
map({ "n", "i" }, "<C-r>", "<Cmd>redo<CR>", { silent = true })
