vim.keymap.set('n', '<leader>q', '<cmd>qa<CR>')
vim.keymap.set('v', '<leader>ss', 'y/\\V<C-r>"<Return>', { desc = '[S]earch [S]elected (as plain text)' })
vim.keymap.set('n', 'd', '"_d', { noremap = true, desc = 'Delete without yanking' })
vim.keymap.set('n', 'dd', '"_dd', { noremap = true, desc = 'Delete line without yanking' })
vim.keymap.set('n', 'c', '"_c', { noremap = true, desc = 'Change without yanking' })
vim.keymap.set('n', 'cc', '"_cc', { noremap = true, desc = 'Change line without yanking' })
vim.keymap.set('x', '<leader>x', 'd', { noremap = true, desc = 'Cut' })
vim.keymap.set({ 'n', 'x' }, '<leader>X', 'dd', { noremap = true, desc = 'Cut line' })
vim.diagnostic.handlers.loclist = {
  show = function(_, _, _, opts)
    -- Generally don't want it to open on every update
    opts.loclist.open = opts.loclist.open or false
    local winid = vim.api.nvim_get_current_win()
    vim.diagnostic.setloclist(opts.loclist)
    vim.api.nvim_set_current_win(winid)
  end,
}
vim.keymap.set('n', '<leader>dq', function()
  local current_win = vim.api.nvim_get_current_win()
  local win_info = vim.fn.getwininfo(current_win)[1]

  -- Check if current window is a location list window
  if win_info and win_info.loclist == 1 then
    -- We're in the location list, so close it
    vim.cmd 'lclose'
    return
  end

  -- Check if location list exists and has entries
  local loclist = vim.fn.getloclist(0)
  if #loclist > 0 then
    -- Try to focus existing location list window
    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.fn.getwininfo(winid)[1].loclist == 1 then
        vim.api.nvim_set_current_win(winid)
        return
      end
    end
  end
  -- If no location list window found or no entries, open it
  vim.diagnostic.setloclist()
end, { desc = 'Toggle [D]iagnostic [Q]uickfix list' })
