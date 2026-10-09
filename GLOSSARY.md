# Glossary

- **Workflow stack**: this repo plus the user-level installs it links to. Skills, agents, MCP templates, Herdr, OpenCode, and Cursor.
- **Skill**: a `SKILL.md` instruction contract the agent loads. Not a compiled program.
- **Agent**: a markdown role. It can delegate to another agent.
- **Subagent**: an agent spawned for one slice, then finished. It does not own the conversation.
- **Outer loop**: Grok bots that read tasks and hand them inward. They do not replace the local panes.
- **Pane**: one terminal inside Herdr. One pane is Cursor CLI. Another is OpenCode.
- **Issue tracker**: for this repo, markdown files under `.scratch/`. Not the host's issue product.
