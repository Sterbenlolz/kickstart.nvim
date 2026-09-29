-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

vim.pack.add {
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
}

vim.keymap.set('n', '\\', '<Cmd>Neotree reveal<CR>', { desc = 'NeoTree reveal', silent = true })

require('neo-tree').setup {
  filesystem = {
    follow_current_file = { enabled = true },
    window = {
      mappings = {
        ['\\'] = 'close_window',
      },
    },
    filtered_items = {
      visible = true,
    },
    -- Watch the filesystem for changes and automatically refresh the tree.
    -- This makes NeoTree reflect file additions/removals/renames on disk
    -- regardless of which window is focused.
    watcher = {
      -- Debounce interval in milliseconds; lower = more responsive.
      -- Default is 250ms. Keep it low so changes appear quickly.
      debounce_ms = 100,
      -- Include dotfiles (hidden files) in the watch.
      watch_dotfiles = true,
    },
  },
}
