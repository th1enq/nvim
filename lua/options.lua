require "nvchad.options"

-- add yours here!
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99
vim.opt.foldenable = true
-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cur
