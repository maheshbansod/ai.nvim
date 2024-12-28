---
--- deps:
---   plenary : for curl
---


local M = {}

M.setup = function()
  -- nothing to do here
end

local create_prompt_window = function()
  -- i need to create a floating window
  local buf = vim.api.nvim_create_buf(false, true)
  local float_height = 1
  local float_actual_height = float_height + 2
  local config = {
    relative = "cursor",
    row = -float_actual_height,
    col = 0,
    -- row = row,
    -- col = col,
    width = vim.o.columns,
    height = float_height,
    border = "rounded"
  }
  local win = vim.api.nvim_open_win(buf, true, config)
  vim.cmd [[startinsert]]
  return { buf = buf, win = win }
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

  local API_KEY = ""

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
  ---@diagnostic disable-next-line: unused-local
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local total_lines = 100
  local start_row = row - total_lines / 2
  local end_row = row + total_lines / 2

  local surrounding_lines = vim.api.nvim_buf_get_lines(0, start_row, end_row, false)
  local current_line = vim.api.nvim_get_current_line()
  local editor_buf = vim.api.nvim_get_current_buf()

  local prompt_float = create_prompt_window()
  vim.keymap.set("n", "<CR>", function()
    -- take the current contents of the buffer
    local prompt = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
    local replaced_code = generate_replacement_code(prompt, surrounding_lines, current_line)
    local replaced_code_lines = vim.split(replaced_code, '\n')
    if #replaced_code_lines > 0 then
      if replaced_code_lines[1]:find("```") ~= nil then
        table.remove(replaced_code_lines, #replaced_code_lines)
        table.remove(replaced_code_lines, 1)
      end
      vim.api.nvim_buf_set_lines(editor_buf, start_row, end_row, false, replaced_code_lines)
      vim.api.nvim_win_close(prompt_float.win, true)
    end
  end, { buffer = prompt_float.buf })

  vim.print(surrounding_lines)
end
-- create_prompt_window()


return M
