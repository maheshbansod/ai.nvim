local M = {}

local wu = require('window-utils')
local au = require('ai-utils')

---
---@param user_prompt string
---@param surrounding_lines string[]
---@param current_line string
local generate_replacement_code = function(
    user_prompt,
    surrounding_lines,
    current_line,
    on_generated
)
  -- ai gang
  local surrounding_content = table.concat(surrounding_lines, '\n')
  -- todo: maybe add language in the prompt

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
      temperature = 0.7,
      topK = 10,
      topP = 0.3,
      maxOutputTokens = 8192,
      responseMimeType = "text/plain"
    }
  }
  au.llm_run(post_data, function(text)
    if text then
      on_generated(text)
    else
      on_generated(surrounding_content)
    end
  end)
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

  local prompt_float = wu.create_prompt_window()
  local set_keymap = function(mode, keys, cb)
    vim.keymap.set(mode, keys, cb, { buffer = prompt_float.buf })
  end
  set_keymap("n", "<CR>", function()
    -- take the current contents of the buffer
    local prompt = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
    generate_replacement_code(prompt, selected_lines, current_line, function(replaced_code)
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
  end)
end

return M
