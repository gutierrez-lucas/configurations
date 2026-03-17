local wk = require("which-key")

wk.register({
  ["<C-/>"] = { "<cmd>ToggleTerm direction=float<cr>", "Toggle floating terminal" },
  ["<C-\\>"] = { "<cmd>ToggleTerm direction=horizontal<cr>", "Toggle horizontal terminal" },
  ["<leader>tt"] = { "<cmd>ToggleTerm<cr>", "Toggle terminal" },
}, { mode = "n" })
