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
        return require('codecompanion.adapters').extend('tavily', {
          env = {
            api_key = read_secret 'TAVILY_API_KEY',
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

  interactions = {
    chat = {
      adapter = 'ollama',

      opts = {
        system_prompt = [[
Act as an autonomous software-engineering agent.

Your job is to complete the user's requested task, not merely describe how it
could be completed.

WORKFLOW:
1. Understand the task.
2. Inspect the repository using the available tools.
3. Form a plan internally.
4. Make the necessary changes.
5. Inspect your changes.
6. Run appropriate tests, checks, or diagnostics.
7. Fix any problems you discover.
8. Continue until the task is complete.
9. Give the user a concise final summary.

IMPORTANT:
- Do not stop after stating an intention to inspect or modify something.
- If a tool can provide information you need, invoke the tool immediately.
- Do not ask the user to paste files that you can inspect with the available
  tools.
- Do not ask permission before reading project files or performing routine
  coding operations.
- Do not wait for a user response after statements such as "I'll check...",
  "Let me inspect...", or "I'll look at...".
- Treat those statements as actions that must immediately be followed by the
  appropriate tool call.
- Only ask the user a question when you truly cannot proceed without their
  input.
- Empty or meaningless user prompts should never be required to continue work.
- Continue working after each tool result instead of returning control to the
  user unnecessarily.

When you have modified code, verify the changes before declaring the task
complete.
]],
        context_management = {
          enabled = true,

          editing = {
            -- Start removing old tool results at 55%
            -- of the available context window.
            trigger = 0.55,

            -- Keep the most recent 3 agent cycles intact.
            keep_cycles = 3,
          },

          compaction = {
            -- Summarize the conversation at 75%.
            trigger = 0.75,

            -- Only compact if at least 8K tokens
            -- can actually be saved.
            min_token_savings = 8000,

            -- Use the same Ollama model for compaction.
            adapter = nil,

            -- If compaction fails, retry using the chat adapter.
            fallback_to_chat_adapter = true,
          },
        },

        default_tools = {
          'agent',
          'files',
          'web_search',
        },

        tools = {
          opts = {
            max_output_tokens = 20000,
          },
        },
      },

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

      sessions = {
        enabled = true,
        autosave = true,
        continuous_save = true,
      },
    },

    inline = {
      adapter = 'ollama',
    },
  },
}
