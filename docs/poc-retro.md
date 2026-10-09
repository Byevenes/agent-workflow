# Retro

The proof for this cut is this repository, not a sample function in another repo.

## What held

- Matt's skills installed under `~/.agents/skills` at commit `49dd158`.
- The skills CLI said it copied them into Cursor and OpenCode. Those folders did not contain `grill-with-docs` afterward. `scripts/link.sh` is the copy that actually creates the missing links, and it does not replace a name that is already there.
- pstack `0.15.15` was already installed. It was not reinstalled.
- Herdr `0.9.3` installed, with the OpenCode and Cursor CLI integrations.
- `cursor-team-kit` `1.2.0` is in the local plugins folder.
- `gh` logged in with the device page plus the two-digit approval in the GitHub app. The dashed code is only for `https://github.com/login/device`. The two digits appear on that page after the code is submitted, and the app asks to approve those digits.

## What to change next time

- Do not hand someone the dashed device code as if it were the app approval.
- Run `scripts/link.sh` after the skills CLI. Do not trust the CLI's copy step alone.
- The skills installer can replace `~/.agents/skills/tdd`. See `docs/value-review.md`.
- GitHub, GitLab, and Postgres MCP entries read environment variables. Until those variables are set, those servers do not start. Playwright does not need one.
- `scripts/link.sh` first looked for a directory named `SKILL.md`, so the pstack skills were not linked into OpenCode. It now looks for the `SKILL.md` file and links the parent directory. Names that already exist are linked as `pstack-<name>`.
- Herdr created a workspace labeled `workflow-smoke` in this repo's directory, split it into two panes, and started OpenCode in one and Cursor CLI in the other. The workspace was created without taking focus. A first split landed in the already focused workspace; that extra pane was closed.
