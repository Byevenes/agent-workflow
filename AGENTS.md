# Agent skills

### Issue tracker

Issues and specs live as markdown under `.scratch/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Five default role labels, names unchanged. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Who does what

Every coding task starts with `skills/route-work` (always on through `rules/route-work.mdc`). Map: `docs/software-factory.md`.

- `route-work` classifies, plans, and checks. It never edits in the parent chat.
- `agents/implementer.md` writes the code for every size and loads `poteto-mode` first (`poteto-mode: loaded`).
- `agents/coordinator.md` is the same router as a subagent, for when a parent wants one.
- Reviews: `code-reviewer` (medium and up), `security-auditor` (critical).
