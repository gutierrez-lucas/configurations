return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = "nvim-tree/nvim-web-devicons",
  config = function()
    require("bufferline").setup{
      options = {
        mode = "buffers", -- or "tabs"
        numbers = "ordinal",
        diagnostics = "nvim_lsp",
        separator_style = "slant",
        show_buffer_close_icons = true,
        show_close_icon = false,
        always_show_bufferline = true,
        highlights = {
          buffer_selected = {
            bold = true,
            italic = true,
          },
        },
      }
    }
  end,
}

