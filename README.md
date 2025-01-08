# ai.nvim

AI in neovim.

> [!WARNING]  
> Work in progress.

Currently supports gemini.

### Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
-- plugins/ai.lua
return {
    'maheshbansod/ai.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('ai').setup({
        -- It needs an API key to access the Gemini API
        api_key_getter = function()
          -- get it from a file
          local path = vim.fn.stdpath('data') .. "/secrets/google_ai_api_key"
          local lines = vim.fn.readfile(path)
          return lines[1]
        end
      })
      -- You can set a keymap
      vim.keymap.set({ 'n', 'v' }, '<M-k>', require 'ai'.get_ai_suggestion)
    end
  }
```

### Usage

`:AiSuggestion` in normal mode or visual mode.

-> opens a floating window where one can write a prompt  
-> press `<enter>`  
-> AI content will replace the selected text  

### Future

- Chat
    - Can be file level, selection level, or codebase level.
- Approval system - not really sure rn how 
    - maybe should also show the diff
