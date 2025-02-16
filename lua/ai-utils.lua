local M = {}


---@class ai.Config
---@field api_key string|nil
---@field api_key_getter nil|fun():string

---@type ai.Config
M.plugin_config = {}

local get_api_key = function()
  local api_key = M.plugin_config.api_key
  if api_key then
    return api_key
  else
    local new_api_key = M.plugin_config.api_key_getter()
    M.plugin_config.api_key = new_api_key
    return new_api_key
  end
end

M.llm_run = function(post_data, on_exit)
  local API_KEY = get_api_key()

  local curl = require('plenary.curl')
  local url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=" ..
      API_KEY

  curl.post(url, {
    body = vim.fn.json_encode(post_data),
    headers = {
      content_type = "application/json",
    },
    callback = function(res)
      vim.schedule(function()
        res = vim.fn.json_decode(res.body)
        ---@type string
        local text = res.candidates[1].content.parts[1].text
        on_exit(text)
      end)
    end
  })
end

M.llm_run_streamed = function(post_data, on_next_line, on_end)
  local API_KEY = get_api_key()

  local curl = require('plenary.curl')
  local url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:streamGenerateContent?key=" ..
      API_KEY

  local partial_chunk = ""

  curl.post(url, {
    body = vim.fn.json_encode(post_data),
    headers = {
      content_type = "application/json",
    },
    stream = function(_, chunk)
      partial_chunk = partial_chunk .. chunk
      pcall(function()
        local data = vim.json.decode(partial_chunk .. "]")
        vim.defer_fn(function()
          on_next_line(data[#data].candidates[1].content.parts[1].text)
        end, 0)
      end)
    end,
    callback = function()
      vim.defer_fn(on_end, 0)
    end
  })
end

---TODO: think about this later
local a = require('plenary.async')
M.llm_run_async = a.wrap(M.llm_run, 2)

return M
