---
--- deps:
---   plenary : for curl
---

local M = {}

---@param config ai.Config
local setup = function(config)
  require 'ai-utils'.plugin_config = config
end

M.get_ai_suggestion = require 'quick_suggestion'.get_ai_suggestion

M.start_chat = require 'chat'.start_chat

M.setup = setup

return M
