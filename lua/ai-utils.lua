local M = {}


---@class ai.Config
---@field api_key string|nil
---@field api_key_getter nil|fun():string

---@type ai.Config
M.plugin_config = {}

M.get_api_key = function()
  local api_key = M.plugin_config.api_key
  if api_key then
    return api_key
  else
    local new_api_key = M.plugin_config.api_key_getter()
    M.plugin_config.api_key = new_api_key
    return new_api_key
  end
end

return M
