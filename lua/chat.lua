local M = {}

local wu = require 'window-utils'
local au = require 'ai-utils'
local message_separator = "----------"

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
    elseif line:match('^' .. message_separator .. '$') then
      -- ignore the line
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

  local parent_buf = vim.api.nvim_get_current_buf()
  local extra_information = {
    filetype = vim.bo.filetype,
    filename = vim.api.nvim_buf_get_name(parent_buf)
  }
  local split = wu.create_chat_window()

  vim.api.nvim_create_autocmd('QuitPre', {
    group = vim.api.nvim_create_augroup('AiChatParentBufCloseGroup', {}),
    callback = function(event)
      if event.buf == parent_buf then
        if vim.api.nvim_win_is_valid(split.win) then
          vim.api.nvim_win_close(split.win, false)
          vim.api.nvim_del_augroup_by_id(event.group)
        end
      end
    end
  })

  vim.api.nvim_set_hl(0, 'UserMessageHighlight', { fg = '#0000ff' })
  vim.fn.matchadd('UserMessageHighlight', '\\(^User: \\)\\@<=\\_.\\{\\-\\}\\(\\(' ..
    message_separator .. '\\)\\|\\%$\\)\\@=')
  vim.api.nvim_set_hl(0, 'UserLabelHighlight', { fg = '#0000ff', bold = true })
  vim.fn.matchadd('UserLabelHighlight', '^User: ')
  vim.bo.filetype = 'markdown'


  -- vim.api.nvim_set_hl(0, 'AIMessageHighlight', { fg = '#ff0000' })
  -- vim.fn.matchadd('AIMessageHighlight', '\\(^AI: \\)\\@<=\\_.\\{\\-\\}\\(\\(' .. message_separator .. '\\)\\|\\%$\\)\\@=')
  -- vim.api.nvim_set_hl(0, 'AILabelHighlight', { fg = '#ff0000', bold = true })
  -- vim.fn.matchadd('AILabelHighlight', '^AI: ')

  vim.api.nvim_buf_set_lines(split.buf, 0, 0, false, { "User: " })


  vim.keymap.set('n', '<leader><enter>', function()
    -- this function should send current chat context to AI and
    -- then get the response and append it in the window and
    -- then an option to apply it to somewhere maybe.

    local chat_lines = vim.api.nvim_buf_get_lines(split.buf, 0, -1, false)
    local conversation = chat_to_conversation(chat_lines)
    local llm_contents = conversation_to_llm_contents(conversation)
    au.llm_run({
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

]] .. "The user is currently looking at the file '" .. extra_information.filename .. "'\n"
                .. "It's file type is " .. extra_information.filetype
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
    }, function(responseText)
      -- append the output to chat directly for now - maybe i'll parse it at one point idk
      local text = "\n" .. message_separator .. "\nAI: " .. responseText .. "\n" .. message_separator .. "\nUser: "
      local text_lines = vim.split(text, '\n')
      vim.api.nvim_buf_set_lines(split.buf, -1, -1, false, text_lines)
    end)
  end)

  -- let's put some stuff inside the window
  -- it needs to have a title (maybe)
  -- it needs to have a place for prompt - i think i can do something like zed
end
return M
