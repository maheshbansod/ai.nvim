---
--- deps:
---   plenary : for curl
---


---@class ai.Config
---@field api_key string|nil
---@field api_key_getter nil|fun():string

---@type ai.Config
local plugin_config = {}

local M = {}

---@param config ai.Config
local setup = function(config)
  plugin_config = config
end

M.setup = setup

local create_prompt_window = function()
  -- i need to create a floating window
  local buf = vim.api.nvim_create_buf(false, true)
  local inner_lines = 3
  local get_config = function()
    local float_actual_height = inner_lines + 2
    return {
      relative = "cursor",
      row = -float_actual_height,
      col = 0,
      -- row = row,
      -- col = col,
      width = vim.o.columns,
      height = inner_lines,
      border = "rounded",
      title = "Enter a prompt",
      footer = "<Enter> to run"
    }
  end
  local win = vim.api.nvim_open_win(buf, true, get_config())
  vim.cmd [[startinsert]]
  return { buf = buf, win = win }
end

local get_api_key = function()
  local api_key = plugin_config.api_key
  if api_key then
    return api_key
  else
    local new_api_key = plugin_config.api_key_getter()
    plugin_config.api_key = new_api_key
    return new_api_key
  end
end

---
---@param user_prompt string
---@param surrounding_lines string[]
---@param current_line string
---@return string
local generate_replacement_code = function(
    user_prompt,
    surrounding_lines,
    current_line
)
  -- ai gang
  local surrounding_content = table.concat(surrounding_lines, '\n')
  -- todo: maybe add language in the prompt

  local API_KEY = get_api_key()

  local curl = require('plenary.curl')
  local url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=" ..
      API_KEY

  local post_data = {
    contents = {
      {
        role = "user",
        parts = {
          {
            text =
                "I'\''m looking at the line\n```\n" ..
                current_line .. "\n```\nThe surrounding code is:\n```\n" ..
                surrounding_content .. "\n```\n" .. user_prompt .. "\n"
          }
        }
      },
    },
    systemInstruction = {
      role = "user",
      parts = {
        {
          text =
          "You are an expert software engineer and produce high quality code.\nYour task is to respond with code that satisfies the user'\''s requirements.\nUser will send surrounding code. The surrounding code is a part of the whole code.\nThe user'\''s surrounding code would be totally replaced with your output.\nSo ensure that you send code that would fit exactly. Do not add any explanation or anything else before or after the code."
        }
      }
    },
    generationConfig = {
      temperature = 1,
      topK = 40,
      topP = 0.95,
      maxOutputTokens = 8192,
      responseMimeType = "text/plain"
    }
  }
  local res = curl.post(url, {
    body = vim.fn.json_encode(post_data),
    headers = {
      content_type = "application/json",
    },
  }).body
  res = vim.fn.json_decode(res)
  ---@type string
  local text = res.candidates[1].content.parts[1].text
  if text then
    return text
  else
    return surrounding_content
  end
end

M.get_ai_suggestion = function()
  -- get the selection
  local vstart = vim.fn.getpos("'<")
  local vend = vim.fn.getpos("'>")
  local start_row = vstart[2]
  local end_row = vend[2]
  local selected_lines = vim.fn.getline(start_row, end_row)
  if type(selected_lines) == "string" then
    selected_lines = { selected_lines }
  end

  -- if selection isn't available then get surrounding
  if start_row == end_row and start_row == 0 and end_row == 0 then
    local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local total_lines = 100
    start_row = math.max(row - total_lines / 2, 0)
    end_row = row + total_lines / 2
    selected_lines = vim.api.nvim_buf_get_lines(0, start_row, end_row, false)
  end

  local current_line = vim.api.nvim_get_current_line()

  local editor_buf = vim.api.nvim_get_current_buf()

  local prompt_float = create_prompt_window()
  local set_keymap = function(mode, keys, cb)
    vim.keymap.set(mode, keys, cb, { buffer = prompt_float.buf })
  end
  set_keymap("n", "<CR>", function()
    -- take the current contents of the buffer
    local prompt = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
    local replaced_code = generate_replacement_code(prompt, selected_lines, current_line)
    local replaced_code_lines = vim.split(replaced_code, '\n')
    if #replaced_code_lines > 0 then
      if replaced_code_lines[1]:find("```") ~= nil then
        -- remove the last line that starts with ```
        local last_line_index = #replaced_code_lines
        while last_line_index > 0 do
          if replaced_code_lines[last_line_index]:find("```") then
            table.remove(replaced_code_lines, last_line_index)
            break
          else
            table.remove(replaced_code_lines, last_line_index)
          end
          last_line_index = last_line_index - 1
        end

        -- remove the first line
        table.remove(replaced_code_lines, 1)
      end
      vim.api.nvim_buf_set_lines(editor_buf, start_row, end_row, false, replaced_code_lines)
      vim.api.nvim_win_close(prompt_float.win, true)
    end
  end)
end


return M
