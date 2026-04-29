-- ~/.config/nvim/lua/plugins/git-conflict.lua
return {
  "akinsho/git-conflict.nvim",
  version = "*",
  event = { "VimEnter", "BufReadPost", "BufNewFile" },
  opts = {
    default_mappings = true,
    disable_commands = false,
    debug = false,
    disabled_filetypes = { "cmp_docs", "cmp_menu", "OverseerForm" },
    default_description = [[
      < Their changes
      > Your changes
    ]],
    disable_diagnostics = false,
    disable_diff = false,
    indicators = {
      first = "╭",
      middle = "├",
      last = "╰",
      former = "╮",
      stacked = "│",
      untracked = "◍",
      modified = "◉",
      added = "▎",
      deleted = "✘",
      changed = "▍",
      renamed = "➜",
      unmerged = "═",
      unknown = "",
    },
    colors = {
      former = "#E5534B",
      current = "#4ABBF3",
      incoming = "#4ABA8B",
      mixed = "#BDB52C",
    },
    modes = {
      current = "CURRENT",
      incoming = "INCOMING",
      both = "BOTH",
      all = "ALL",
    },
  },
}