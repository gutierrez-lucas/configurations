return {
  "nvim-telescope/telescope.nvim",
  opts = function(_, opts)
    opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
      layout_strategy = "vertical",
      layout_config = {
        vertical = {
          mirror = true,
          prompt_position = "top",
          preview_cutoff = 0,
          preview_height = 0.4,
        },
      },
    })
    return opts
  end,
}
