vim.pack.add { 'https://github.com/olimorris/codecompanion.nvim' }

require('codecompanion').setup({adapters = {
    http = {
      ollama = function()
        return require("codecompanion.adapters").extend("ollama", {
          env = {
            url = "http://192.168.8.212:11434",
          },
                schema = {
          model = {
            default = "qwen3.8",
          },
        },
        })
      end,
    },
  },
  strategies = {
    chat = {
      adapter = "ollama",
    },
    inline = {
      adapter = "ollama",
    },
  },})
