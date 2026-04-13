require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

vim.api.nvim_create_user_command("Tree", function()
  require("utils.tree").open_tree()
end, {})
-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
