return {
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
}
