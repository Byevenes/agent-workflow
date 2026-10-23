# Retro 2026-10-22: route-work in a client project

## What happened

Batch of UI bugs on one branch. In hundreds of Cursor sessions on that project, only a handful asked for `route-work`; none launched `poteto-agent`. All of them edited in the parent chat after labeling the task Small.

## Root cause

- `route-work` had `disable-model-invocation: true`, so it loaded only when named by hand.
- Small said "hand the task to implementer", but nothing required a Task launch, so the parent edited directly.
- `poteto-mode` is user-invoked too, so `implementer` never read it unless told the path.
- Repo rules still pointed at an older spec chain.

## Fix (PR "orchestrator by default")

- `rules/route-work.mdc` with `alwaysApply: true`, linked into `~/.cursor/rules/`.
- `route-work` requires the `implementer` subagent for every size and rejects a report without `poteto-mode: loaded`.
- `implementer` reads `poteto-mode` by path first.
- `scripts/route-audit.sh` for the fixed retro check.

## Fixed retro check

- ¿Se invocó route-work?
- ¿implementer lanzó poteto-mode? (conteo con `scripts/route-audit.sh <proyecto> <días>`)
