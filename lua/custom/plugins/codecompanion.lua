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

local function get_lsp_target(method)
  local current_win = vim.api.nvim_get_current_win()
  local candidates = {}
  local seen = {}

  local function add_window(win)
    if win and win ~= current_win and vim.api.nvim_win_is_valid(win) and not seen[win] then
      seen[win] = true
      candidates[#candidates + 1] = win
    end
  end

  -- Prefer the source window that was active before opening chat.
  local previous_win = vim.fn.win_getid(vim.fn.winnr '#')
  add_window(previous_win)
  add_window(current_win)

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    add_window(win)
  end

  for _, win in ipairs(candidates) do
    local bufnr = vim.api.nvim_win_get_buf(win)

    if vim.bo[bufnr].buftype == '' and vim.bo[bufnr].filetype ~= 'codecompanion' then
      for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
        if client:supports_method(method, bufnr) then return {
          win = win,
          bufnr = bufnr,
          client = client,
        } end
      end
    end
  end

  return nil, ('No source buffer has an LSP client supporting %s'):format(method)
end

local function lsp_position_params(target) return vim.lsp.util.make_position_params(target.win, target.client.offset_encoding) end

local function lsp_request(target, method, params, timeout)
  local response, err = target.client:request_sync(method, params, timeout or 8000, target.bufnr)

  if not response then return nil, err or 'LSP request failed or timed out' end

  if response.err then return nil, response.err.message or vim.inspect(response.err) end

  return response.result
end

local function format_location(location)
  local uri = location.uri or location.targetUri
  local range = location.range or location.targetSelectionRange or location.targetRange

  if not uri or not range then return nil end

  return ('%s:%d:%d'):format(vim.uri_to_fname(uri), range.start.line + 1, range.start.character + 1)
end

-- Creates a CodeCompanion function-based tool.
local function make_lsp_tool(name, description, properties, required, run, opts)
  local schema = {
    type = 'function',
    ['function'] = {
      name = name,
      description = description,
      parameters = {
        type = 'object',
        properties = properties or {},
        required = required or {},
        additionalProperties = false,
      },
    },
  }

  return {
    description = description,
    opts = opts or {},

    callback = {
      name = name,
      description = description,
      system_prompt = description,
      schema = schema,

      cmds = {
        function(_, args)
          local ok, result, err = pcall(run, args)

          if not ok then return {
            status = 'error',
            data = tostring(result),
          } end

          if result == nil then return {
            status = 'error',
            data = err or 'LSP operation failed',
          } end

          return {
            status = 'success',
            data = result,
          }
        end,
      },
    },
  }
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
            url = 'https://ollama.orlovskyy.duckdns.org',
          },

          schema = {
            model = {
              default = 'qwen3.8:latest',
            },
            num_ctx = {
              default = 65536,
            },
            keep_alive = {
              default = '30m',
            },
          },
        })
      end,
    },
  },

  interactions = {
    chat = {
      adapter = 'ollama',

      tools = {
        opts = {
          default_tools = {
            'agent',
            'files',
            'web_search',
            'lsp',
          },

          max_output_tokens = 6000,
        },

        web_search = {
          adapter = 'tavily',
          opts = {
            max_results = 4,
          },
        },

        groups = {
          agent = {
            opts = {
              collapse_tools = true,
              ignore_system_prompt = false,
              ignore_tool_system_prompt = false,
            },
          },
          lsp = {
            description = 'Neovim LSP tools for symbol operations and code navigation',

            system_prompt = [[
Use these tools whenever a task involves symbol renaming, references,
definitions, or understanding the structure of the current source file.

Prefer language-server results over project-wide text searches for semantic
code operations. The tools operate on the source window and cursor position,
normally the window active before the chat was opened.

Rename operations can modify multiple files. Only rename when the user's
request makes the intended new name clear, and report any LSP errors.
The other tools return compact locations or symbol outlines, not full files.
]],

            tools = {
              'lsp_rename_symbol',
              'lsp_find_references',
              'lsp_go_to_definition',
              'lsp_document_symbols',
            },

            opts = {
              collapse_tools = true,
              ignore_system_prompt = false,
              ignore_tool_system_prompt = false,
            },
          },
        },

        lsp_rename_symbol = make_lsp_tool(
          'lsp_rename_symbol',
          'Rename the symbol at the source cursor using the language server and apply its workspace edit.',
          {
            new_name = {
              type = 'string',
              description = 'The new name for the symbol',
            },
          },
          { 'new_name' },
          function(args)
            if type(args.new_name) ~= 'string' or args.new_name == '' then return nil, 'new_name must be a non-empty string' end

            local target, err = get_lsp_target 'textDocument/rename'
            if not target then return nil, err end

            local params = lsp_position_params(target)
            params.newName = args.new_name

            local edit, request_err = lsp_request(target, 'textDocument/rename', params, 10000)

            if not edit then return nil, request_err or 'The language server returned no rename edit' end

            vim.lsp.util.apply_workspace_edit(edit, target.client.offset_encoding)

            return ('Renamed the symbol to "%s" using %s.'):format(args.new_name, target.client.name)
          end,
          {
            require_approval_before = true,
          }
        ),

        lsp_find_references = make_lsp_tool(
          'lsp_find_references',
          'Find references to the symbol at the source cursor. Return file locations, not file contents.',
          {},
          {},
          function()
            local target, err = get_lsp_target 'textDocument/references'
            if not target then return nil, err end

            local params = lsp_position_params(target)
            params.context = { includeDeclaration = true }

            local references, request_err = lsp_request(target, 'textDocument/references', params)

            if not references then return nil, request_err or 'No reference result returned' end

            if #references == 0 then return 'No references found.' end

            local lines = {}
            local limit = math.min(#references, 40)

            for i = 1, limit do
              local location = format_location(references[i])
              if location then lines[#lines + 1] = location end
            end

            if #references > limit then lines[#lines + 1] = ('... %d more references omitted'):format(#references - limit) end

            return ('Found %d reference(s):\n%s'):format(#references, table.concat(lines, '\n'))
          end
        ),

        lsp_go_to_definition = make_lsp_tool(
          'lsp_go_to_definition',
          'Find the definition of the symbol at the source cursor. Return file locations without reading whole files.',
          {},
          {},
          function()
            local target, err = get_lsp_target 'textDocument/definition'
            if not target then return nil, err end

            local result, request_err = lsp_request(target, 'textDocument/definition', lsp_position_params(target))

            if not result then return nil, request_err or 'No definition found' end

            -- A definition can be one Location, one LocationLink, or a list.
            if result.uri or result.targetUri then result = { result } end

            local lines = {}

            for _, location in ipairs(result) do
              local formatted = format_location(location)
              if formatted then lines[#lines + 1] = formatted end
            end

            if #lines == 0 then return 'No definition locations found.' end

            return table.concat(lines, '\n')
          end
        ),

        lsp_document_symbols = make_lsp_tool(
          'lsp_document_symbols',
          'Get a compact outline of symbols in the source file from its language server. Do not return file contents.',
          {},
          {},
          function()
            local target, err = get_lsp_target 'textDocument/documentSymbol'
            if not target then return nil, err end

            local symbols, request_err = lsp_request(target, 'textDocument/documentSymbol', {
              textDocument = {
                uri = vim.uri_from_bufnr(target.bufnr),
              },
            })

            if not symbols then return nil, request_err or 'No document symbols returned' end

            local kind_names = {
              [2] = 'module',
              [5] = 'class',
              [6] = 'method',
              [10] = 'enum',
              [11] = 'interface',
              [12] = 'function',
              [13] = 'variable',
              [14] = 'constant',
              [23] = 'struct',
            }

            local lines = {}
            local limit = 60

            local function add_symbols(items, depth)
              for _, symbol in ipairs(items or {}) do
                if #lines >= limit then return end

                local range = symbol.selectionRange or symbol.range or (symbol.location and symbol.location.range)

                local line = range and (range.start.line + 1) or '?'
                local kind = kind_names[symbol.kind] or ('kind ' .. tostring(symbol.kind))

                lines[#lines + 1] = ('%s%s (%s) — line %s'):format(string.rep('  ', depth), symbol.name or '<unnamed>', kind, line)

                if symbol.children then add_symbols(symbol.children, depth + 1) end
              end
            end

            add_symbols(symbols, 0)

            if #lines == 0 then return 'No document symbols found.' end

            if #lines >= limit then lines[#lines + 1] = '... symbol list truncated' end

            return table.concat(lines, '\n')
          end
        ),
      },
    },
  },
}
