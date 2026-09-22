vim.pack.add { 'https://github.com/Wansmer/treesj' }

require('treesj').setup {
  use_default_keymaps = false, -- Disables default <gS> and <gJ> mappings so you can set your own
}

vim.keymap.set('n', '<leader>m', function()
  require('treesj').toggle()
end, { desc = 'Toggle TreeSJ (Split/Join code block)' })
