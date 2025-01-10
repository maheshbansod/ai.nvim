local M = {}

local wu = require 'window-utils'
local au = require 'ai-utils'

---@alias Message {role: "user"|"ai", text: string}
---@alias Conversation {messages: Message[]}

---Convert lines to a conversation
---@param lines string[]
local chat_to_conversation = function(lines)
  ---@type (Message)[]
  local messages = {}
  for _, line in ipairs(lines) do
    if line:match('^AI: ') then
      local text = line:sub(3)
      table.insert(messages, { text = text, role = "ai" })
    elseif line:match('^User: ') then
      local text = line:sub(3)
      table.insert(messages, { text = text, role = "user" })
    else
      local last_message = messages[#messages]
      last_message.text = last_message.text .. '\n' .. line
    end
  end
  return { messages = messages }
end

---Convert conversations to LLM contents that can be directly sent
---@param conversation Conversation
local conversation_to_llm_contents = function(conversation)
  local messages = conversation.messages
  local contents = {}
  for _, message in ipairs(messages) do
    table.insert(contents, {
      role = message.role == "user" and "user" or "model",
      parts = {
        text = message.text
      }
    })
  end
  return contents
end

M.start_chat = function()
  -- opens a window
  -- initialises with some settings probably

  local split = wu.create_chat_window()

  vim.api.nvim_buf_set_lines(split.buf, 0, 0, false, { "User: " })

  vim.keymap.set('n', '<leader><enter>', function()
    -- this function should send current chat context to AI and
    -- then get the response and append it in the window and
    -- then an option to apply it to somewhere maybe.

    local chat_lines = vim.api.nvim_buf_get_lines(split.buf, 0, -1, false)
    local conversation = chat_to_conversation(chat_lines)
    local llm_contents = conversation_to_llm_contents(conversation)
    local text = au.llm_run({
      contents = llm_contents,
      systemInstruction = {
        role = "user",
        parts = {
          {
            text = [[
You are an expert senior software engineer and produce high quality code.
The user is the developer.
You are having a conversation with the user and your task is to provide code snippets to the developer.
Ensure that your code is clean and exhaustively solves the user's problem.
]]
          }
        }
      },
      generationConfig = {
        temperature = 0.7,
        topK = 10,
        topP = 0.3,
        maxOutputTokens = 8192,
        responseMimeType = "text/plain"
      }
    })

    -- append the output to chat directly for now - maybe i'll parse it at one point idk
    text = "\nAI: " .. text .. "\nUser: "
    local text_lines = vim.split(text, '\n')
    vim.api.nvim_buf_set_lines(split.buf, -1, -1, false, text_lines)
  end)

  -- let's put some stuff inside the window
  -- it needs to have a title (maybe)
  -- it needs to have a place for prompt - i think i can do something like zed
end

return M
