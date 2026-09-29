vim.pack.add { 'https://github.com/MeanderingProgrammer/render-markdown.nvim' }

require('render-markdown').setup {
  file_types = { 'markdown', 'codecompanion' },
  opts = {
    render_modes = true, -- Render in ALL modes
    sign = {
      enabled = false, -- Turn off in the status column
    },
  },
}
