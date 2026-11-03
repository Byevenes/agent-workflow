# Glossary

- **Workflow stack**: this repo plus the user-level installs it links to. Skills, agents, MCP templates, OpenCode, and Cursor.
- **Skill**: a `SKILL.md` instruction contract the agent loads. Not a compiled program.
- **Agent**: a markdown role. It can delegate to another agent.
- **Subagent**: an agent spawned for one slice, then finished. It does not own the conversation.
- **Outer loop**: Grok bots that read tasks and hand them inward. They do not replace the local sessions.
- **Issue tracker**: for this repo, markdown files under `.scratch/`. Not the host's issue product.
- **zStack**: the whole flow, from intake to retro (`skills/zstack`). `route-work` is its alias until 2026-12-01.
- **zIGL**: the router role that classifies, plans and checks (`agents/zigl.md`, and the zstack skill itself).
- **zNinja**: the implementer subagent (`agents/zninja.md`).
- **zSensei**: the reviewer subagent (`agents/zsensei.md`).
- **zHunter, zGuard**: reserved names, no role yet.
