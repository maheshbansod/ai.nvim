vim.api.nvim_create_user_command("AiSuggestion", function()
  print("ai sugsetion running")
  require("ai").get_ai_suggestion()
end, { range = true })
