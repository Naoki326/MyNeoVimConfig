vim.g.mapleader = " "

local map = vim.keymap.set
map({ "n", "i" }, "<C-z>", "<Cmd>undo<CR>", { silent = true })
map({ "n", "i" }, "<C-r>", "<Cmd>redo<CR>", { silent = true })

map({ "n" }, "<C-h>", "<C-w>h<CR>", { silent = true })
map({ "n" }, "<C-j>", "<C-w>j<CR>", { silent = true })
map({ "n" }, "<C-k>", "<C-w>k<CR>", { silent = true })
map({ "n" }, "<C-l>", "<C-w>l<CR>", { silent = true })

