-- ~/.config/nvim/lua/plugins/hovercraft.lua
return {
  "patrickpichler/hovercraft.nvim",
  dependencies = {
    { "nvim-lua/plenary.nvim" },
  },
  opts = function()
    return {
      providers = {
        providers = {
          { "LSP",  require("hovercraft.provider.lsp.hover").new() },
          { "Man",  require("hovercraft.provider.man").new() },
        },
      },
      window = {
        border = "rounded",
        padding = { left = 1, right = 1 },
      },
      keys = {
        { "<C-u>",   function() require("hovercraft").scroll({ delta = -4 }) end },
        { "<C-d>",   function() require("hovercraft").scroll({ delta = 4 }) end },
        { "<Tab>",   function() require("hovercraft").hover_next() end },
        { "<S-Tab>", function() require("hovercraft").hover_next({ step = -1 }) end },
      },
    }
  end,
}
