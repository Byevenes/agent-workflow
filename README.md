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

Define with Matt Pocock (`grill-with-docs`, then `to-spec`). Implement with pstack (`poteto-mode`). Close with `retro`. Herdr holds a Cursor CLI pane and an OpenCode pane. Grok bots sit on the outer loop: Engineer Lead splits work, Dr Eggbot designs bots, Think-a-bot is recorded in `docs/grok-roster.md`.

The skill that encodes that order is `skills/route-work`. The agent that delegates, and does not implement, is `agents/coordinator.md`.
