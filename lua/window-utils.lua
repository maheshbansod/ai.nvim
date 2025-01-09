local M = {}
M.create_prompt_window = function()
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
return M
