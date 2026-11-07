# Steering documents

Comparison of `skills/zretro/SKILL.md` with the external retro skill and the external writing-for-agents skill. Sources in this repo: the zretro text and `docs/agents/`. The external skills stay outside this repo.

## What each one does

`skills/zretro/SKILL.md` is a wrapper. It reads `~/.agents/skills/retro/SKILL.md` and adds local rules: prefer a structural fix, then a type, a test, or a `scripts/check.sh` guard; rule text is last; delete a sentence when a barrier replaces it; review every pendiente. Its trigger is the end of a Medium, Large, or Critical task, a Small task that had an error, or a correction. If the external retro file is missing, it falls back to seven category names: navigation, automated checks, coding standards, steering files, tool economy, no-ops, information access.

The external retro skill is the session review that wrapper follows. Its first step loads the writing-for-agents skill as the style guide. It treats `AGENTS.md` as a short list of navigation pointers, and it treats coding standards as material for the reviewer. It does not contain the writing procedure.

The external writing-for-agents skill is the procedure for a document an agent reads: a skill, `AGENTS.md`, or a doc reached by a pointer. Its trigger is creating or editing those documents, not closing a session.

`docs/agents/domain.md`, `docs/agents/issue-tracker.md`, and `docs/agents/triage-labels.md` say how to consume the glossary, the local issue files, and the five triage labels. They do not say how to write `AGENTS.md` or a rule.

## Gaps

1. zretro never names the writing skill. The style guide arrives only when the external retro file is present and its first step runs. The local fallback is seven category names and no writing procedure.
2. The only `AGENTS.md` instruction in zretro is to delete a sentence after a barrier replaces it. It does not say what the file should contain, how short it stays, or where a rule lives.
3. zretro runs after a session. It does not run when the task is to write or edit `AGENTS.md` or a rule.
4. `docs/agents/` has no authoring steps and no pointer to the writing skill. An agent that only reads those pages learns where the glossary and the tracker are, not how to shape `AGENTS.md`.
5. The external retro skill keeps writing in a separate skill and calls it. Copying that procedure into zretro would mix a session review with document authoring, and this change does not edit zretro.

## Decision

New skill: `skills/zwrite/SKILL.md`.

It writes `AGENTS.md` and rules under `rules/`. It does not rewrite `skills/zretro/SKILL.md`.
