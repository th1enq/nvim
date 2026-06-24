local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    go = { "goimports" },
    nix = { "nixfmt-rfc-style" },
    cpp = { "clang-format"},
    py = { "isort"},
    -- css = { "prettier" },
    --
    -- html = { "prettier" },
  },

  format_on_save = {
    timeout_ms = 2000,
    lsp_format = "fallback",
  },
}

return options
