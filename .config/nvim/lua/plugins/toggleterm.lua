return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({
      open_mapping = [[<c-\>]],
      direction = "float",
      size = function(term)
        if term.direction == "horizontal" then
          return vim.o.lines * 0.25
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        elseif term.direction == "float" then
          return {
            width = math.ceil(vim.o.columns * 0.7),
            height = math.ceil(vim.o.lines * 0.7),
          }
        end
      end,
      shading_factor = -10,
      float_opts = {
        border = "curved",
        title_pos = "center",
      },
    })
  end,
}
