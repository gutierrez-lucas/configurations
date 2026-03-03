-- ~/.config/nvim/lua/plugins/lsp.lua
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- disable inlay hints globally
      inlay_hints = { enabled = false },

      servers = {
        clangd = {
          cmd = { "clangd" },
          init_options = {
            inlayHints = { enabled = false },
          },
        },
        pyright = {},
        gopls = {},
        tsserver = {},
      },
    },
  },
}
