# Retro 2026-11-02: zStack rename, run with zStack itself

Large, full verifiable. Run headless by Grok Bot on its own box, no Task tool, so every role ran inline (`zninja launched: no (inline: headless, no subagents)`).

## What helped

- Classification first and the spec's "how do we measure success" forced a check to exist before any edit; `scripts/check.sh` was written to that line.
- The repo rule "align every copy" turned into one grep in `check.sh`, and its negative test (drifted sentence, stray comment) failed as expected.

## Friction

- Large says "stop for approval before code", but the user had approved the whole run up front; the skill had no wording for that. Added.
- Inline mode makes zSensei a second author pass, so decision 18 (fresh-context reviewer) cannot hold in headless runs. The review found real drift (`docs/value-review.md` kept old names), which a grep would have caught: now in `check.sh` scope is a follow-up.
- Decisions 24, 27, 32 and 34 target upstream Matt skills that are not in this repo; they live as zStack steps plus a `setup-check.sh` report, not as edits to those skills.
- One-PR-per-slice is not prescribed anywhere; the flow only says one zNinja per slice.

## Turned into a barrier (decision 29)

- `scripts/check.sh` (alignment, banned references, no-comments, shellcheck) on pre-commit, pre-push and CI.
