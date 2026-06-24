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

local imports_group = vim.api.nvim_create_augroup("user_organize_imports", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
	group = imports_group,
	pattern = "*.java",
	callback = function(args)
		local clients = vim.lsp.get_clients({ bufnr = args.buf, name = "jdtls" })
		local client = clients[1]

		if not client then
			return
		end

		local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
		params.context = { diagnostics = {} }

		local response = client:request_sync("java/organizeImports", params, 3000, args.buf)
		if response and response.result then
			vim.lsp.util.apply_workspace_edit(response.result, client.offset_encoding)
		end
	end,
})
