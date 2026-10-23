# agent-workflow

Portable setup for one working style across machines: skills, agents, MCP templates, Herdr, OpenCode, and Cursor.

The git repo is the source of truth. A clone plus `scripts/link.sh` points the user-level skill and agent folders at this tree. Upstream skills (Matt Pocock, pstack) are installed from their own sources and pinned in `docs/upstream.md`. They are not forked here.

## Install on a new machine

1. Install the GitHub CLI and authenticate: `gh auth login`. Paste the dashed code at `https://github.com/login/device`. The GitHub app then asks you to approve the two digits shown on that page.
2. Clone this repo.
3. Install [Matt Pocock's skills](https://github.com/mattpocock/skills) globally for Cursor and OpenCode. The pin is in `docs/upstream.md`.
4. Install the Cursor plugin `pstack` (already the user-level plugin on the machine that published this repo) and `cursor-team-kit`.
5. Install Herdr and its OpenCode and Cursor integrations. See `docs/workflow.md`.
6. Export tokens only in the environment, never in git: `GITHUB_PERSONAL_ACCESS_TOKEN`, `GITLAB_PERSONAL_ACCESS_TOKEN`, `POSTGRES_URL`.
7. Run `scripts/link.sh`, then `scripts/setup-check.sh`.

`scripts/setup-check.sh` prints command names and symlink status. It does not print secret values.

## How work moves

`rules/route-work.mdc` is always applied, so every new session starts with `skills/route-work`. It classifies the change (small, medium, large, critical), runs Matt Pocock's planning skills for that size, and launches the `implementer` subagent, which loads `poteto-mode` before writing code. Medium and up add `code-reviewer`; critical adds `security-auditor`; every run ends with a `route-work check` block. The map is in `docs/software-factory.md`; `scripts/route-audit.sh` counts whether it really happened.

Grok bots sit on the outer loop: Engineer Lead splits work, Dr Eggbot designs bots, Think-a-bot is recorded in `docs/grok-roster.md`. The agent that delegates, and does not implement, is `agents/coordinator.md`.

## How each tool starts the workflow

| Tool | Entry point |
| --- | --- |
| Cursor (IDE and `agent` CLI) | `~/.cursor/rules/route-work.mdc`, always applied |
| OpenCode | `default_agent: "route-work"` (`agents/opencode/route-work.md`) plus `~/.config/opencode/route-work.md` in `instructions` |
| OpenCode Sisyphus (oh-my-openagent) | `prompt_append` that points to `route-work.md`; the global `instructions` also apply |
| Grok Bot | delegates code to the Cursor `agent` CLI, so the Cursor rule applies |
| Any other harness | read `rules/route-work.mdc` first |

Subagents: `implementer` (loads `poteto-mode`) and `code-reviewer` (checks the spec still matches the diff). The OpenCode agents default to free OpenCode Zen models.
