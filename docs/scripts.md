# Scripts

Scripts carry no comments (decision 20: only issue or RFC links and license lines are allowed). What each one does:

- `scripts/link.sh`: points the user-level Cursor and OpenCode folders at this repo, removes old route-work links that point here, and sets `core.hooksPath` to `.githooks`. It never replaces a regular file; directories under `~/.agents/skills` are added only when the name is absent. Matt skills under `~/.agents/skills` are mirrored into Cursor and OpenCode; pstack skills from the Cursor plugin cache go into OpenCode, as `pstack-<name>` when the plain name is taken.
- `scripts/setup-check.sh`: reports whether the local setup resolves, whether the `zgrill`, `zspec` and `ztickets` wrappers and Matt's skills they read are present, whether `tdd` is model-invocable, and the optional MCP env vars (not failures). Never prints secret values.
- `scripts/route-audit.sh [project-filter] [days]`: retro counts from Cursor transcripts under `~/.cursor/projects` (zstack or route-work invoked, zninja or implementer launched, poteto-mode loaded by zninja, inline edits with and without a stated reason). Counts only.
- `scripts/mcp-gitlab.sh`, `scripts/mcp-postgres.sh`: start those MCP servers; the token or URL stays in the environment.
- `scripts/check.sh`: the repo's automatic barrier. Runs in `.githooks/pre-commit` (after the main-branch and staged-secret guards) and CI. There is no pre-push hook: CI runs the same check and GitHub protects `main`.
