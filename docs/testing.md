# Testing

This repo is a setup, not an application. Its check is `scripts/setup-check.sh`. That script reports commands and paths. It does not print tokens or `POSTGRES_URL`.

When the work is code in another repo:

- Matt Pocock's `tdd` skill is the red-green-refactor loop.
- pstack's `poteto-mode` picks the playbook and is the implementation entry.
- Playwright checks a screen.
- Postgres is used only when the spec touches the database, through `POSTGRES_URL`.

`agent-browser` remains available. Do not remove it in this cut.
