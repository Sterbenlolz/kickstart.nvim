-- ============================================================
-- snacks.nvim
-- https://github.com/folke/snacks.nvim
--
-- Installed via `vim.pack` (no lazy.nvim).
--
-- NOTES:
--  - Your config already uses Telescope as the primary picker
--    (<leader>s*), so `Snacks.picker` is left DISABLED here to avoid
--    keymap/UX conflicts. It's included and commented out if you want
--    to switch.
--  - `mini.statusline` is your current statusline and mini.nvim's
--    `indent` overlaps with snacks.indent, so those are disabled.
--  - LazyGit: we now use Snacks' built-in lazygit integration instead
--    of kdheepak/lazygit.nvim (see lazygit.lua, which is commented out).
-- ============================================================

vim.pack.add { 'https://github.com/folke/snacks.nvim' }

---@type snacks.Config
local snacks_config = {
  -- [[ Notifier ]]
  -- Pretty `vim.notify` with a history window.
  notifier = {
    enabled = true,
    timeout = 3000,
  },

  -- [[ Bigfile ]]
  -- Automatically disable features on big files to keep Neovim fast.
  bigfile = {
    enabled = true,
  },

  -- [[ Scroll ]]
  -- Smooth scrolling.
  scroll = {
    enabled = true,
  },

  -- [[ Input ]]
  -- Better `vim.ui.input` (e.g. for `:Confirm`, `vim.fn.input` with a window).
  input = {
    enabled = true,
  },

  -- [[ Quickfile ]]
  -- Render files quickly before loading plugins.
  quickfile = {
    enabled = true,
  },

  -- [[ Scope ]]
  -- Scope detection / text objects (treesitter or indent based).
  scope = {
    enabled = true,
  },

  -- [[ Statuscolumn ]]
  -- Pretty status column (diagnostics, git signs, etc.)
  --
  -- If you prefer mini.statusline / the default sign column,
  -- you can disable this or set `signcolumn = false` below.
  statuscolumn = {
    enabled = false,
  },

  -- [[ Indent ]]
  -- Indent guides & scopes. Disabled because mini.nvim provides
  -- `mini.statusline` and may conflict with indent guides you already use.
  -- If you want indent guides from snacks, enable it.
  indent = {
    enabled = false,
  },

  -- [[ Explorer ]]
  -- A file explorer (a picker in disguise).
  -- Left disabled to keep your current explorer/keymaps.
  explorer = {
    enabled = false,
  },

  -- [[ Dashboard ]]
  -- Beautiful declarative dashboards (e.g. on `:startuptime` / empty buffer).
  dashboard = {
    enabled = false,
  },

  -- [[ Picker ]]
  -- A built-in fuzzy picker. DISABLED by default since you already use
  -- Telescope. If you want to switch, enable it and map keys below.
  picker = {
    enabled = false,
  },

  -- [[ Terminal ]]
  -- Floating/split terminals via `Snacks.terminal`.
  terminal = {
    enabled = true,
  },

  -- [[ Zen ]]
  -- Zen mode / distraction-free coding.
  zen = {
    enabled = true,
  },

  -- [[ Lazygit ]]
  -- Better integration than the standalone lazygit.nvim plugin:
  --  - Opens LazyGit in a float
  --  - Auto-configures the LazyGit colorscheme from your active colorscheme
  --  - Provides useful keymaps
  lazygit = {
    enabled = true,
  },

  -- [[ Words ]]
  -- Auto-show LSP references & quick navigation.
  -- Requires an LSP attached; safe to enable.
  words = {
    enabled = true,
  },
}

require('snacks').setup(snacks_config)

-- ============================================================
-- Keymaps (only non-conflicting ones are active)
-- ============================================================
local Snacks = require 'snacks'

-- Notifications
vim.keymap.set('n', '<leader>n', Snacks.notifier.show_history, { desc = 'Notification History' })
vim.keymap.set('n', '<leader>un', Snacks.notifier.hide, { desc = 'Dismiss All Notifications' })

-- Terminal (toggle floating terminal)
vim.keymap.set('n', '<c-/>', function() Snacks.terminal() end, { desc = 'Toggle Terminal' })

-- Lazygit (via Snacks integration)
vim.keymap.set('n', '<leader>lg', function() Snacks.lazygit() end, { desc = 'Open LazyGit' })

-- Zen mode
vim.keymap.set('n', '<leader>z', function() Snacks.zen() end, { desc = 'Toggle Zen Mode' })

-- Scratch buffer
vim.keymap.set('n', '<leader>.', function() Snacks.scratch() end, { desc = 'Toggle Scratch Buffer' })
vim.keymap.set('n', '<leader>S', function() Snacks.scratch.select() end, { desc = 'Select Scratch Buffer' })

-- Words (LSP references) — only if an LSP is active
vim.keymap.set('n', '[[', function() Snacks.words.jump(-vim.v.count1) end, { desc = 'Prev Reference', remap = true })
vim.keymap.set('n', ']]', function() Snacks.words.jump(vim.v.count1) end, { desc = 'Next Reference', remap = true })

-- Neovim news in a window
vim.keymap.set(
  'n',
  '<leader>N',
  function()
    Snacks.win {
      file = vim.api.nvim_get_runtime_file('doc/news.txt', false)[1],
      width = 0.6,
      height = 0.6,
      wo = {
        spell = false,
        wrap = false,
        signcolumn = 'yes',
        statuscolumn = ' ',
        conceallevel = 3,
      },
    }
  end,
  { desc = 'Neovim News' }
)

-- ============================================================
-- OPTIONAL: Toggle keymaps (Snacks.toggle integrates with which-key)
-- These are optional; enable the ones you want.
-- ============================================================
-- Toggle keymaps
-- Snacks.toggle handles the keymap registration itself via :map(keys)
Snacks.toggle.option('spell', { name = 'Spelling' }):map '<leader>us'
Snacks.toggle.option('wrap', { name = 'Wrap' }):map '<leader>uw'
Snacks.toggle.option('relativenumber', { name = 'Relative Number' }):map '<leader>uL'
Snacks.toggle.diagnostics():map '<leader>ud'
Snacks.toggle.line_number():map '<leader>ul'
Snacks.toggle.inlay_hints():map '<leader>uh'

-- ============================================================
-- OPTIONAL: Snacks.picker mappings (DISABLED — conflicts with Telescope)
-- Uncomment if you decide to switch your primary picker to Snacks.
-- ============================================================
-- vim.keymap.set('n', '<leader><space>', function() Snacks.picker.smart() end, { desc = 'Smart Find Files' })
-- vim.keymap.set('n', '<leader>,', function() Snacks.picker.buffers() end, { desc = 'Buffers' })
-- vim.keymap.set('n', '<leader>/', function() Snacks.picker.grep() end, { desc = 'Grep' })
-- vim.keymap.set('n', '<leader>:', function() Snacks.picker.command_history() end, { desc = 'Command History' })
-- vim.keymap.set('n', '<leader>e', function() Snacks.explorer() end, { desc = 'File Explorer' })
-- vim.keymap.set('n', '<leader>ff', function() Snacks.picker.files() end, { desc = 'Find Files' })
-- vim.keymap.set('n', '<leader>fg', function() Snacks.picker.git_files() end, { desc = 'Find Git Files' })
-- vim.keymap.set('n', '<leader>sg', function() Snacks.picker.grep() end, { desc = 'Grep' })
-- vim.keymap.set('n', '<leader>ss', function() Snacks.picker.lsp_symbols() end, { desc = 'LSP Symbols' })
-- vim.keymap.set('n', '<leader>sS', function() Snacks.picker.lsp_workspace_symbols() end, { desc = 'LSP Workspace Symbols' })
-- vim.keymap.set('n', '<leader>sq', function() Snacks.picker.qflist() end, { desc = 'Quickfix List' })
-- vim.keymap.set('n', '<leader>sh', function() Snacks.picker.help() end, { desc = 'Help Pages' })
