-- ~/.config/nvim/lua/plugins/snacks.lua
return {
  "folke/snacks.nvim",
  opts = {
    explorer = {
      show_hidden = true,
      show_gitignored = true,
      always_show = { ".gitignore" },
    },
  },
  config = function(_, opts)
    require("snacks").setup(opts)
    print("Snacks override loaded!") -- debug message
  end,
}
