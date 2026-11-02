# Agent skills

### Issue tracker

Issues and specs live as markdown under `.scratch/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Five default role labels, names unchanged. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Who does what

Every coding task starts with `skills/zstack` (always on through `rules/zstack.mdc`). Map: `docs/software-factory.md`.

- `zstack` classifies, plans, and checks. Run inline when the Task tool is absent, or its subagent list does not include zninja, or one launch attempt returned an error (quote it in the reason), or this session is a whole task that arrived with no parent and is running headless without subagents; if the Task tool exists and lists zninja, you must launch it. Otherwise the `zninja` subagent writes the code.
- `agents/zninja.md` writes the code for every size and loads `poteto-mode` first (`poteto-mode: loaded`), as a subagent or on that inline fallback.
- `agents/zigl.md` is the same router as a subagent, for when a parent wants one.
- Reviews: `zsensei` (medium and up), `security-auditor` (critical).
