-- ~/.config/nvim/lua/plugins/snacks.lua
return {
  "folke/snacks.nvim",
  opts = {
    dashboard = {
      preset = {
        header = [[
 __   __ ___  __  __
 \ \ / /|_ _||  \/  |
  \ V /  | | | |\/| |
   \_/  |___||_|  |_|]],
      },
      sections = {
        { section = "header", padding = 1 },
        { section = "keys", gap = 0, padding = 1 },
        { section = "startup" },
      },
    },
    picker = {
      layout = {
        preset = "vertical",
        layout = { width = 0.8 },
      },
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
        },
      },
    },
  },
}
