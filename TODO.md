
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

- [ ] Chat window for continous chats
    - A keymap will call LLM to add some next things in the chat.
    - I want clear separation of AI message and user message I think.
    - I am not 100% sure about how do I represent symbols that link to parts of code/files or something.
        One way would be to probably use everything plaintext and display and then parse it, another would probably 
        involve maintaining a datastructure such that it's parsed only part of it is displayed.


#### Completion and AI refactoring

I don't think I want auto-completion like Cursor or copilot, but I do want intentional AI auto-completion

- [ ] A way to just do completion
- [ ] Renamed variables should trigger vim functions.

#### Auto Agent

- [ ] A mode for AI to get functions related to vim too maybe - like refactoring, go to definition, etc
- [ ] A way for AI to search documentation and then store it to use it again too.
