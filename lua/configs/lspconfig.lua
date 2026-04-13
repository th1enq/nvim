require("nvchad.configs.lspconfig").defaults()

vim.lsp.config("gopls", {
  settings = {
    gopls = {
      completeUnimported = true,
      staticcheck = true,
    },
  },
})

vim.lsp.config("clangd", {
  cmd = {
    "clangd",
    "--query-driver=/etc/profiles/per-user/th1enq/bin/g++"
  },
})


local servers = { "html", "cssls", "nixd", "gopls", "clangd" }
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers 
