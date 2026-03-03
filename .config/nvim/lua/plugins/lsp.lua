-- ~/.config/nvim/lua/plugins/lsp.lua
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- disable inlay hints globally
      inlay_hints = { enabled = false },
      require("lspconfig").clangd.setup({
        -- handlers = handlers,
        capabilities = capabilities,
        cmd = { "./clangd", "--background-index", "--compile-commands-dir=build", "--query-driver=*" },
        root_dir = function()
          -- leave empty to stop nvim from cd'ing into ~/ due to global .clangd file
        end,
      }),
      servers = {
        clangd = {
          -- cmd = { "clangd", "--compile-commands-dir=build", "--query-driver=/path/to/xtensa-esp32-elf-gcc" },
          cmd = {
            "clangd",
            "--compile-commands-dir=build",
            "--query-driver=/home/lucas/.espressif/tools/xtensa-esp-elf/esp-14.2.0_20250730/xtensa-esp-elf/bin/xtensa-esp32-elf-gcc",
          },
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
