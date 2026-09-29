-- ============================================================
-- tiny-cmdline.nvim
-- Repositions the cmdline as a centered floating window,
-- powered by Neovim's native ui2 system (requires Neovim >= 0.12).
--
-- The plugin auto-initializes on UIEnter (see plugin/tiny-cmdline.lua)
-- and is idempotent, so this setup() call is safe.
-- ============================================================
vim.o.cmdheight = 0
vim.pack.add { 'https://github.com/rachartier/tiny-cmdline.nvim' }
require('vim._core.ui2').enable {}

require('tiny-cmdline').setup {
  -- Width as a fraction of editor columns (clamped between min/max).
  -- Change `value` to e.g. "70%" or an integer for an absolute width.
  width = {
    value = '60%',
    min = 40,
    max = 80,
  },

  -- Horizontal / vertical center of the window.
  position = {
    x = '50%',
    y = '50%',
  },

  -- nil = inherit vim.o.winborder; set "rounded"/"single"/"none" to force.
  border = 'rounded',

  -- Offset for the completion menu relative to the window's left inner edge.
  -- Only relevant if you use the blink adapter below (or nvim-cmp).
  menu_col_offset = 3,

  -- Cmdline types that stay at the bottom at full width (native search UX).
  -- Remove "/" and "?" from this list to center search prompts too.
  native_types = { '/', '?' },

  -- Optional: show a title on the border (e.g. " Lua ", " Search ").
  title = { enabled = false, pos = 'center' },

  -- Reposition the blink.cmp completion menu to follow the cmdline window.
  -- You use blink.cmp, so this keeps the menu aligned with the repositioned
  -- cmdline. Remove this line if you switch to another completion engine.
  on_reposition = require('tiny-cmdline').adapters.blink,
}
