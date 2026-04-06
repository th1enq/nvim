require "nvchad.autocmds"

local fold_group = vim.api.nvim_create_augroup("user_fold_options", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
	group = fold_group,
	callback = function()
		vim.opt_local.foldmethod = "expr"
		vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
		vim.opt_local.foldlevel = 99
		vim.opt_local.foldenable = true
	end,
})
