# Agent skills

### Issue tracker

Issues and specs live as markdown under `.scratch/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Five default role labels, names unchanged. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Who does what

- `agents/coordinator.md` routes. It does not implement.
- `agents/implementer.md` builds the task. Small has no spec. Medium, large, and critical build from one.
- Start a change with the `route-work` skill. It picks the size.
