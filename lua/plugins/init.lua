return {
  {
    "stevearc/conform.nvim",
    event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },
  {
    "mfussenegger/nvim-jdtls",
    ft = { "java" },
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "java",
        callback = function()
          require("configs.jdtls").start()
        end,
      })
      require("configs.jdtls").start()
    end,
  },
  {
    "JavaHello/spring-boot.nvim",
    ft = { "java", "yaml", "jproperties" },
    dependencies = {
      "mfussenegger/nvim-jdtls",
    },
    opts = {},
  },
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = function()
      return require "configs.telescope"
    end,
  },
  {
      "MeanderingProgrammer/render-markdown.nvim",
      ft = { "markdown" },
      dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-tree/nvim-web-devicons",
      },
      opts = {
        enabled = true,
        file_types = { "markdown" },

        -- render ở normal / command / terminal mode
        render_modes = { "n", "c", "t" },

        -- bật completion cho checkbox/callout qua LSP nội bộ của plugin
        completions = {
          lsp = {
            enabled = true,
          },
        },

        heading = {
          enabled = true,
        },

        code = {
          enabled = true,
          sign = false,
          width = "block",
          right_pad = 1,
        },

        pipe_table = {
          enabled = true,
          preset = "round",
        },

        checkbox = {
          enabled = true,
        },

        quote = {
          enabled = true,
        },
      },
    },
  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  -- {
  -- 	"nvim-treesitter/nvim-treesitter",
  -- 	opts = {
  -- 		ensure_installed = {
  -- 			"vim", "lua", "vimdoc",
  --      "html", "css"
  -- 		},
  -- 	},
  -- },
}
