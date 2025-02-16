local M = {}

local wu = require 'window-utils'
local au = require 'ai-utils'
local message_separator = "----------"

---@alias ContextFile {name: string, content: string}
---@alias ConversationContext {files: ContextFile[]}
---@alias Message {role: "user"|"ai", text: string}
---@alias Conversation {messages: Message[], conversation_context: ConversationContext}

---@param input_string string
local function extract_filepaths(input_string)
  local pattern = "@file:([^%s]+)"
  ---@type string[]
  local filepaths = {}
  for filepath in string.gmatch(input_string, pattern) do
    table.insert(filepaths, filepath)
  end
  return filepaths
end

---Convert lines to a conversation
---@param lines string[]
local chat_to_conversation = function(lines)
  ---@type (Message)[]
  local messages = {}
  local context_files_map = {}
  for _, line in ipairs(lines) do
    if line:match('^AI: ') then
      local text = line:sub(4)
      table.insert(messages, { text = text, role = "ai" })
    elseif line:match('^User: ') then
      local text = line:sub(7)
      table.insert(messages, { text = text, role = "user" })
    elseif line:match('^' .. message_separator .. '$') then
      -- ignore the line
    else
      local last_message = messages[#messages]
      if last_message.text:match("^%s*$") then
        last_message.text = line
      else
        last_message.text = last_message.text .. '\n' .. line
      end
    end
    local file_paths = extract_filepaths(line)
    for _, file_path in ipairs(file_paths) do
      if context_files_map[file_path] == nil then
        local file, err = io.open(file_path, "r")
        if not file then
          print(err)
          goto continue
        end
        local content = file:read("*a")
        context_files_map[file_path] = content
        file:close()
      end
      ::continue::
    end
  end
  ---@type ContextFile[]
  local context_files = {}
  for name, content in pairs(context_files_map) do
    table.insert(context_files, { name = name, content = content })
  end
  ---@type Conversation
  local conversation = {
    messages = messages,
    conversation_context = { files = context_files }
  }
  return conversation
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

---@param conversation Conversation
local function conversation_context_message(conversation)
  if next(conversation.conversation_context) == nil then
    return ""
  end
  if next(conversation.conversation_context.files) == nil then
    return ""
  end
  ---@type string
  local message = "\nThese are some of the files that are referenced in the conversation:\n"
  for _, file_data in ipairs(conversation.conversation_context.files) do
    local name = file_data.name
    local content = file_data.content
    message = message .. "==== Start of file `" .. name .. "`\n"
        .. content
        .. "\n==== End of file `" .. name .. "`\n"
  end
  return message
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


  local user_message_color = "#00FF00"
  vim.api.nvim_set_hl(0, 'UserMessageHighlight', { fg = user_message_color })
  vim.fn.matchadd('UserMessageHighlight', '\\(^User: \\)\\@<=\\_.\\{\\-\\}\\(\\(' ..
    message_separator .. '\\)\\|\\%$\\)\\@=')
  vim.api.nvim_set_hl(0, 'UserLabelHighlight', { fg = user_message_color, bold = true })
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
    local llm_context_message = conversation_context_message(conversation)
    local loading_message = "thinking..."
    vim.api.nvim_buf_set_lines(split.buf, -1, -1, false, { "", message_separator, "AI: " .. loading_message })
    local loading_message_removed = false;
    au.llm_run_streamed({
      contents = llm_contents,
      systemInstruction = {
        role = "user",
        parts = {
          {
            text = [[
You are an expert senior software engineer. Your responses are curt and to the point.
You only respond with details when the user explicitly asks for it. You may consider yourself as a pair programmer.
The user might ask you questions about anything. Be to the point and answer the questions they have.
If you see anything concerning, then point it out.
If you see code quality issues, then point it out.
Your purpose is for the user to quickly finish their tasks so you can return to their work as well as the user learn something from this session.

]] .. "The user is currently looking at the file '" .. extra_information.filename .. "'\n"
                .. "It's file type is " .. extra_information.filetype
                .. llm_context_message
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
      local text = responseText
      local text_lines = vim.split(text, '\n')
      local start_col = -1
      if not loading_message_removed then
        start_col = - #loading_message - 1
        loading_message_removed = true
        table.insert(text_lines, 1, "")
      end
      vim.api.nvim_buf_set_text(split.buf, -1, start_col, -1, -1, text_lines)
      -- vim.api.nvim_buf_set_lines(split.buf, -2, -1, false, text_lines)
    end, function()
      vim.api.nvim_buf_set_lines(split.buf, -1, -1, false, { "", message_separator, "User: " })
    end)
  end)

  -- let's put some stuff inside the window
  -- it needs to have a title (maybe)
  -- it needs to have a place for prompt - i think i can do something like zed
end
return M
