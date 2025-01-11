
# TODO

- [x] Get API key from setup or env
    - i think i need the env option or some way so that i don't need to commit it in any repo
- [ ] Set shortcut key in plugin config
- [ ] See if there's automatic doc generator
- [ ] Prompt floating window should autoposition if it's OOB
- Prompt floating window should auto-increase height on:
    - [ ] New line by user
    - [ ] On completion of one prompt, it should give space for the next while still showing the old one
- [ ] Spinner or something to show loading while API response is comin

#### Chat stuff

- [x] Chat window for continous chats
- [ ] Add context with @<some code symbol>.
- [ ] RAG on the current file (if the file is big enough)
- [ ] Allow adding current file as context.
- [ ] Different colors for AI message and user message maybe.
- [ ] Auto scroll down to user prompt when AI response appears probably?
- [ ] Stream AI response + autoscroll while streaming.
    - I want to do this in a non-invasive way
- [ ] Apply code block
    - without context - search in the file where to put the code first.
    - with context it can directly select what parts of the context to replace.


#### Completion and AI refactoring

I don't think I want auto-completion like Cursor or copilot, but I do want intentional AI auto-completion

- [ ] A way to just do completion
- [ ] Renamed variables should trigger vim functions.

#### Auto Agent

- [ ] A mode for AI to get functions related to vim too maybe - like refactoring, go to definition, etc
- [ ] A way for AI to search documentation and then store it to use it again too.

#### Code explainer

Explains some code.  
I want a mode where I can maybe select a block of code and press a keybinding (`<leader>ak` maybe) 
and then it generates a floating window that explains the given block

