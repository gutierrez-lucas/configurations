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
      },
      highlights = {
        -- The active buffer tab itself
        buffer_selected = {
          bold = true,
          italic = false,
          fg = "#ffffff",
          bg = "#3d59a1",
        },
        -- The number shown on the active buffer
        numbers_selected = {
          bold = true,
          fg = "#ffffff",
          bg = "#3d59a1",
        },
        -- The close icon on the active buffer
        close_button_selected = {
          fg = "#ffffff",
          bg = "#3d59a1",
        },
        -- Diagnostic icons on the active buffer
        diagnostic_selected = {
          bold = true,
          bg = "#3d59a1",
        },
        hint_selected = {
          bold = true,
          bg = "#3d59a1",
        },
        info_selected = {
          bold = true,
          bg = "#3d59a1",
        },
        warning_selected = {
          bold = true,
          bg = "#3d59a1",
        },
        error_selected = {
          bold = true,
          bg = "#3d59a1",
        },
        -- Inactive buffers dimmed down
        buffer_visible = {
          fg = "#565f89",
          bg = "#1a1b26",
        },
        buffer = {
          fg = "#565f89",
          bg = "#1a1b26",
        },
        -- Left/right separators for the selected buffer
        separator_selected = {
          fg = "#3d59a1",
          bg = "#3d59a1",
        },
      },
    }
  end,
}

