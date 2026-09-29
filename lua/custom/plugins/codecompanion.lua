vim.pack.add { 'https://github.com/olimorris/codecompanion.nvim' }

--- Read a secret from ~/.local/share/nvim/secrets.env (dotenv-style).
--- Returns nil if the file or key is missing, so the caller can fall back.
local function read_secret(name)
  local path = vim.fn.stdpath 'data' .. '/secrets.env'
  local f = io.open(path, 'r')
  if not f then return nil end
  for line in f:lines() do
    local key, value = line:match '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$'
    if key == name and value and value ~= '' then
      f:close()
      return value
    end
  end
  f:close()
  return nil
end

require('codecompanion').setup {
  adapters = {
    http = {
      tavily = function()
        local api_key = read_secret 'TAVILY_API_KEY'
        if not api_key then
          vim.notify('codecompanion: TAVILY_API_KEY not found in ~/.local/share/nvim/secrets.env — web_search will not work', vim.log.levels.WARN)
          return nil
        end
        return require('codecompanion.adapters').extend('tavily', {
          env = {
            api_key = api_key,
          },
        })
      end,
      ollama = function()
        return require('codecompanion.adapters').extend('ollama', {
          env = {
            url = 'http://192.168.8.212:11434',
          },
          schema = {
            model = {
              default = 'qwen3.8',
            },
          },
        })
      end,
    },
  },
  strategies = {
    chat = {
      adapter = 'ollama',
      tools = {
        web_search = {
          opts = {
            adapter = 'tavily',
            opts = {
              max_results = 8,
            },
          },
        },
      },
      opts = {
        default_tools = {
          'agent',
          'files',
          'web_search',
        },
        tools = {
          opts = {
            max_output_tokens = 100000,
          },
        },
      },
      sessions = {
        enabled = true,
        autosave = true,
        continuous_save = true,
      },
    },
    inline = {
      adapter = 'ollama',
      -- Enter is owned by blink.cmp (LSP completion accept),
      -- so use <C-y> ([y]es) to accept a suggestion while the inline window is open.
      -- <Esc> still dismisses, <Tab>/<S-Tab> still cycle suggestions.
      keymaps = {
        accept = '<Enter>',
        send = { modes = { i = '<Enter>' } },
      },
    },
  },
}
