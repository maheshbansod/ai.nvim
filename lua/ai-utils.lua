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

M.llm_run = function(post_data)
  local API_KEY = get_api_key()

  local curl = require('plenary.curl')
  local url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=" ..
      API_KEY

  local res = curl.post(url, {
    body = vim.fn.json_encode(post_data),
    headers = {
      content_type = "application/json",
    },
  }).body
  res = vim.fn.json_decode(res)
  ---@type string
  local text = res.candidates[1].content.parts[1].text
  return text
end

return M
