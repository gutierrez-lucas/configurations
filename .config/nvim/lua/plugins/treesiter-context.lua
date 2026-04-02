-- ~/.config/nvim/lua/plugins/treesitter-context.lua
return {
    "nvim-treesitter/nvim-treesitter-context",
      config = function()
          require("treesitter-context").setup({
                  enable = true,
                        max_lines = 3,
                              trim_scope = "outer",
                                  })

              -- Softer highlight: dimmed italic text, no background
                  vim.cmd [[
                        hi TreesitterContext guifg=#AAAAAA guibg=bold gui=italic
                            ]]
                                -- Optional: underline only
                                    vim.cmd [[
                                          hi TreesitterContextLineNumber guifg=#888888 gui=underline
                                              ]]
                                                end,
}

