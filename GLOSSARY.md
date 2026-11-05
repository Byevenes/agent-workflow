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
- **Clients root**: where client repos live. Non-empty `CLIENTS_ROOT`, otherwise `clients_root` in the client map, otherwise `$HOME/Clients`.
- **Client map**: local untracked toml at `ZSTACK_CLIENTS_TOML`, or `~/.config/zstack/clients.toml` when that variable is unset. Never commit it.
- **Repo-root path**: a file citation from the repository root, such as `src/Foo/Bar.cs`, written as inline code or as a markdown link target. `scripts/check-repo-paths.sh` rejects a bare name that is not at that root, a working-directory prefix, and a machine-absolute path. It removes a trailing line anchor before the lookup and ignores a glob.
