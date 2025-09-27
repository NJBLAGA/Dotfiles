return {
  { -- Catppuccin theme
    "catppuccin/nvim",
    lazy = true,
    name = "catppuccin",
    opts = {
      transparent_background = true,
      integrations = {
        aerial = true,
        alpha = true,
        cmp = true,
        dashboard = true,
        flash = true,
        gitsigns = true,
        headlines = true,
        illuminate = true,
        indent_blankline = { enabled = true },
        leap = true,
        lsp_trouble = true,
        mason = true,
        markdown = true,
        mini = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        navic = { enabled = true, custom_bg = "lualine" },
        neotest = true,
        neotree = true,
        noice = true,
        semantic_tokens = true,
        telescope = true,
        treesitter = true,
        treesitter_context = true,
        which_key = true,
        bufferline = true,
      },
      --- 🔽 Add this
      custom_highlights = function(c)
        return {
          -- Blink completion menu & docs
          BlinkCmpMenu = { bg = "NONE" },
          BlinkCmpMenuBorder = { bg = "NONE" },
          BlinkCmpDoc = { bg = "NONE" },
          BlinkCmpDocBorder = { bg = "NONE" },
          BlinkCmpSignatureHelp = { bg = "NONE" },
          BlinkCmpSignatureHelpBorder = { bg = "NONE" },

          -- fallback for older cmp/popup groups
          Pmenu = { bg = "NONE" },
          PmenuSel = { bg = c.surface0 }, -- keep selection visible
          NormalFloat = { bg = "NONE" },
          FloatBorder = { bg = "NONE" },
        }
      end,
    },
  },

  { -- LazyVim with catppuccin as colorscheme
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-mocha",
    },
  },

  { -- Bufferline
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = { "catppuccin/nvim" },
    config = function()
      require("bufferline").setup({
        options = {
          separator_style = "slant",
          diagnostics = "nvim_lsp",
        },
      })
    end,
  },
}
