# Agent skills

### Issue tracker

Issues and specs live as markdown under `.scratch/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Five default role labels, names unchanged. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Who does what

Every coding task starts with `skills/zstack` (always on through `rules/zstack.mdc`). Map: `docs/software-factory.md`.

- `zstack` classifies, plans, and checks. The inline trigger is in section 3 of `skills/zstack/SKILL.md`. Otherwise the `zninja` subagent writes the code.
- `agents/zninja.md` writes the code for every size and loads `poteto-mode` first (`poteto-mode: loaded`), as a subagent or on that inline fallback.
- `agents/zigl.md` is the same router as a subagent, for when a parent wants one.
- Reviews: `zsensei` (medium and up), `security-auditor` (critical).
- `skills/zwrite` writes `AGENTS.md` and rules under `rules/`. It does not rewrite `skills/zretro/SKILL.md`.
