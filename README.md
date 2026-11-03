# zStack

Repo: `Byevenes/agent-workflow`.

Portable setup for one working style across machines: skills, agents, MCP templates, OpenCode, and Cursor.

The git repo is the source of truth. A clone plus `scripts/link.sh` points the user-level skill and agent folders at this tree. Upstream skills (Matt Pocock, pstack) are installed from their own sources and pinned in `docs/upstream.md`. They are not forked here.

## Install on a new machine

1. Install the GitHub CLI and authenticate: `gh auth login`. Paste the dashed code at `https://github.com/login/device`. The GitHub app then asks you to approve the two digits shown on that page.
2. Clone this repo.
3. Install [Matt Pocock's skills](https://github.com/mattpocock/skills) globally for Cursor and OpenCode. The pin is in `docs/upstream.md`.
4. Install the Cursor plugin `pstack` (already the user-level plugin on the machine that published this repo) and `cursor-team-kit`.
5. Optional, only for local-token MCPs (mostly OpenCode; leave unset so client data stays out of OpenCode, decision #10). Export tokens only in the environment, never in git: `GITHUB_PERSONAL_ACCESS_TOKEN`, `GITLAB_PERSONAL_ACCESS_TOKEN`, `POSTGRES_URL`.
6. Run `scripts/link.sh`, then `scripts/setup-check.sh`.

`scripts/setup-check.sh` prints command names and symlink status. It does not print secret values.

## How work moves

`rules/zstack.mdc` is always applied, so every new session starts with `skills/zstack`. It classifies the change (small, medium, large, critical), runs Matt Pocock's planning skills for that size, and launches the `zninja` subagent, which loads `poteto-mode` before writing code. The inline trigger is in section 3 of `skills/zstack/SKILL.md`. On that path it runs the same flow in the session and records `zninja launched: no (inline: <reason>)`. Medium and up add `zsensei`; critical adds `security-auditor`; every run ends with a `zstack check` block. The map is in `docs/software-factory.md`; diagrams of the wiring, the task flow and the guardrails are in `docs/architecture.md`. `scripts/route-audit.sh` counts delegated launches only; inline runs show as not launched.

Grok bots sit on the outer loop: Engineer Lead splits work, Dr Eggbot designs bots, Think-a-bot is recorded in `docs/grok-roster.md`. The agent that delegates is `agents/zigl.md`. It writes code only on that inline fallback.

## How each tool starts the workflow

| Tool | Entry point |
| --- | --- |
| Cursor (IDE and `agent` CLI) | `~/.cursor/rules/zstack.mdc`, always applied |
| OpenCode | `default_agent: "zstack"` (`agents/opencode/zstack.md`) plus `~/.config/opencode/zstack.md` in `instructions` |
| OpenCode Sisyphus (oh-my-openagent) | `prompt_append` that points to `zstack.md`; the global `instructions` also apply |
| Grok Bot | delegates code to the Cursor `agent` CLI, so the Cursor rule applies |
| Any other harness | read `rules/zstack.mdc` first |

Subagents: `zninja` (loads `poteto-mode`) and `zsensei` (checks the spec still matches the diff). The OpenCode agents default to free OpenCode Zen models.

## Checks

`scripts/check.sh` keeps the inline trigger in one file, the client `--force` rule, no SDD/tech-lead/test-engineer and no old role names; enforces the no-comments rule in scripts; requires `shellcheck`; smoke-tests `scripts/link.sh` in a temp HOME; and fails after 2026-12-01 while the `route-work` alias remains. `scripts/link.sh` sets `core.hooksPath` to `.githooks`; the pre-commit hook blocks commits on `main` and likely secrets in the staged diff, then runs check.sh; `.github/workflows/check.yml` runs it in CI. Script docs: `docs/scripts.md`.
