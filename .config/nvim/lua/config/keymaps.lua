-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Grep word under cursor / visual selection in root dir (like <leader>sg but pre-filled)
vim.keymap.set("n", "<leader>sw", function()
  require("telescope.builtin").live_grep({
    cwd = LazyVim.root(),
    default_text = vim.fn.expand("<cword>"),
  })
end, { desc = "Grep Word (Root Dir)" })

vim.keymap.set("v", "<leader>sw", function()
  -- yank visual selection into register v, then use it as search text
  vim.cmd('noau normal! "vy"')
  local text = vim.fn.getreg("v")
  require("telescope.builtin").live_grep({
    cwd = LazyVim.root(),
    default_text = text,
  })
end, { desc = "Grep Selection (Root Dir)" })
