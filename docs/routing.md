# Routing

Which host runs which kind of work. This is the only host map. It does not copy models, size thresholds or permissions; those live where they are enforced.

| Host | Runs | Never |
| --- | --- | --- |
| Orchestrator (chat bot) | Coordinates: classifies, plans, delegates, short reports | Heavy code research or long edits on a client project |
| Cursor `agent -p` on the Mac | Heavy work: implementation, code research, technical analyses, reviews, scanner runs, zStack edits, always inside a worktree | Work outside the task worktree |
| OpenCode | Exploration and second opinions on non-client work | Any client project (`$CLIENTS_ROOT/**`) |
| Cloud Agents | Only on an explicit order from the owner | Default host for anything |

## Where the rest lives

- Models per role and quota fallback: `docs/model-matrix.md`.
- Client user story pre-stage: section 0 of `skills/zstack/SKILL.md`.
- Review by size: section 4 of `skills/zstack/SKILL.md`.
- Delivery, merge, push and client commit rules: section 5 of `skills/zstack/SKILL.md`.

When this table and one of those sections disagree, the section wins and this table gets fixed.
