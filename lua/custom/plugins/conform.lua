vim.pack.add { 'https://github.com/stevearc/conform.nvim' }
require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "isort", "black" },
  },
})

-- Format on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    require("conform").format({
      lsp_fallback = true, -- fall back to LSP if no conform formatter matches
      timeout_ms = 1000,
      quiet = false,
    })
  end,
})
