local nvchad_lsp = require "nvchad.configs.lspconfig"

nvchad_lsp.defaults()

local mason_bin = vim.fn.stdpath "data" .. "/mason/bin/"

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
    "--query-driver=/etc/profiles/per-user/th1enq/bin/g++",
  },
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
})

-- LSP config
vim.lsp.config("dockerls", {
  filetypes = { "dockerfile" },
})

vim.lsp.config("docker_compose_language_service", {
  filetypes = { "yaml.docker-compose", "yaml.compose" },
})
vim.lsp.config("lemminx", {
  cmd = { mason_bin .. "lemminx" },
  filetypes = { "xml", "xsd", "xsl", "xslt", "svg" },
  init_options = {
    settings = {
      xml = {
        format = {
          enabled = true,
          splitAttributes = "preserve",
          maxLineWidth = 280,
        },
      },
      xslt = {
        format = {
          enabled = true,
          splitAttributes = "preserve",
          maxLineWidth = 280,
        },
      },
    },
  },
})

vim.lsp.config("yamlls", {
  cmd = { mason_bin .. "yaml-language-server", "--stdio" },
  settings = {
    redhat = {
      telemetry = {
        enabled = false,
      },
    },
    yaml = {
      format = {
        enable = true,
      },
    },
  },
})

local servers = {
  "html",
  "cssls",
  "nixd",
  "gopls",
  "clangd",
  "dockerls",
  "docker_compose_language_service",
  "ruff",
  "lemminx",
  "yamlls",
}
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers 
