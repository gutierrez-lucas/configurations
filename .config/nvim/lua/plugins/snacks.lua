-- ~/.config/nvim/lua/plugins/snacks.lua
return {
  "folke/snacks.nvim",
  opts = {
    dashboard = {
      preset = {
        header = [[
 _   _      _ _
| | | | ___| | | ___
| |_| |/ _ \ | |/ _ \
|  _  |  __/ | | (_) |
|_| |_|\___|_|_|\___/]],
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
          layout = {
            preset = "left",
            layout = { width = 0.3 },
          },
        },
        opencode = {
          layout = {
            preset = "vertical",
            layout = { width = 0.5 },
          },
        },
      },
    },
  },
}
