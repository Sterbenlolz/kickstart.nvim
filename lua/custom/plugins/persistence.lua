-- ============================================================
-- Session preservation (persistence.nvim)
-- https://github.com/folke/persistence.nvim
--
-- Installed via `vim.pack` (no lazy.nvim).
--
-- What it does:
--  - Automatically saves the session (tabs, windows, buffers, layout,
--    folds) when you quit Neovim.
--  - Automatically restores that session the next time you start Neovim
--    in the same project directory.
--
-- So the whole workflow is: edit -> quit -> reopen -> pick up where
-- you left off. No keypress required.
--
-- The <leader>ps / pw / pr / pd keymaps below are OPTIONAL extras —
-- a manual escape hatch for saving before quitting, picking from
-- other saved sessions, or deleting a stale one. Safe to delete the
-- whole keymap section if you never want them.
-- ============================================================

vim.pack.add { 'https://github.com/folke/persistence.nvim' }

---@type persistence.Config
local opts = {
  -- Where sessions are stored. Default is stdpath('state')/sessions.
  -- Leaving this commented out keeps the sensible default.
  -- dir = vim.fn.stdpath('state') .. '/sessions',

  -- [[ Core: fully automatic save/restore ]]
  -- Save the session automatically when Neovim quits (VimLeave).
  auto_save = true,

  -- Restore the session automatically on start (if one exists for
  -- the current working directory).
  auto_restore = true,

  -- [[ Scope ]]
  -- Buffer filetypes to skip when saving (help avoids saving UI/scratch
  -- buffers like telescope, help, gitcommit, etc.)
  ignore_ft = {
    'help',
    'telescope',
    'spectre',
    'gitcommit',
    'fugitive',
    'NvimTree',
    'neo-tree',
  },

  -- Buffers whose path matches any of these patterns are skipped.
  -- Handy to avoid saving scratch/temp files.
  ignore_patterns = {
    vim.fn.stdpath('cache') .. '/', -- neovim cache
  },

  -- [[ Session contents ]]
  -- See `:help sessionoptions` for the full list.
  -- These extra sessionoptions tune what gets captured.
  session_save_extra_commands = {},
  session_autoload_commands = {},

  -- Commands run before saving / after restoring.
  pre_save_commands = { 'bdelete! #' }, -- drop the alternate-file buffer
  post_restore_commands = {},
}

require('persistence').setup(opts)

-- ============================================================
-- OPTIONAL keymaps (manual control — not required for auto mode)
-- ============================================================
-- Pick from all saved sessions (interactive picker).
vim.keymap.set('n', '<leader>ps', function()
  require('persistence').pick()
end, { desc = '[S]ession [S]elect' })

-- Save the current session right now (normally auto-saved on quit).
vim.keymap.set('n', '<leader>pw', function()
  require('persistence').save()
end, { desc = '[S]ession [W]rite/save' })

-- Restore the most recent session for the current directory.
vim.keymap.set('n', '<leader>pr', function()
  require('persistence').load()
end, { desc = '[S]ession [R]estore' })

-- Delete the current directory's session (forgets it).
vim.keymap.set('n', '<leader>pd', function()
  require('persistence').delete()
end, { desc = '[S]ession [D]elete' })
