return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      ensure_installed = {
        "lua",
        "vim",
        "vimdoc",
        "json",   
        "nix",   
        "bash",
        "html",
        "css",
        "go",
        "c",
        "cpp",
        "python",
        "java",
        "xml",
      },

      highlight = {
        enable = true,
      },

      indent = {
        enable = true,
      },
    },
  },
}
