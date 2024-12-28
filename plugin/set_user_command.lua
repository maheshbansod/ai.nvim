vim.api.nvim_create_user_command("AiSuggestion", function()
  require("ai").get_ai_suggestion()
end, {})
