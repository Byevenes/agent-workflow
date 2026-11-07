# Skill audit

Each skill was read against the checks that already fail a bad edit. A cut is a sentence that only teaches a rule a check already enforces. Triggers, constraints, and workflow steps stay. A short file stays whole.

## skills/blast-radius/SKILL.md

- Kept: the whole file (31 lines).
- Cut: none.
- Replaced with a check: none.
- Why: The file is the caller gate. The graph format, the command, and the private and indirect caller rule are the workflow `scripts/blast-radius-callers.sh` runs. `scripts/check.sh` requires the phrases `including private methods and indirect callers` and `The check fails when the report misses one.` The fixture paragraph is the worked example of that gate. The file is short, so it stays.

## skills/route-work/SKILL.md

- Kept: the whole file (8 lines).
- Cut: none.
- Replaced with a check: none.
- Why: The file is a short alias. It names the skill to read, the two accepted classification prefixes, and the removal date. `scripts/check.sh` already fails if that alias is still linked after 2026-12-01. Nothing in the file is generic teaching apart from that pointer.

## skills/to-techspec/SKILL.md

- Kept: the whole file (93 lines).
- Cut: none.
- Replaced with a check: none.
- Why: Cuts are limited to six named skills. This file is outside that set, so it stays. It is the section list and the constraints for that document.

## skills/zgrill/SKILL.md

- Kept: the whole file (14 lines).
- Cut: none.
- Replaced with a check: none.
- Why: The file is short. Every line is a trigger, an output path, a ban on publishing, or a question the workflow must ask. No check encodes those questions.

## skills/zpr/SKILL.md

- Kept: the whole file (22 lines).
- Cut: none.
- Replaced with a check: none.
- Why: The file is short. The numbered sections are the workflow for a pull-request body. The line about the three headings restates that workflow, and the check workflow enforces the headings. Cutting it would drop a constraint from a short file.

## skills/zretro/SKILL.md

- Kept: every existing sentence.
- Cut: none.
- Replaced with a check: none.
- Why: The file already prefers a structural or deterministic fix before a new rule. The gap was readiness. One bullet was added. An added agent or a written rule is not ready unless the proposal says why a hook, lint, test, or type is not enough. No script was changed. The existing order, the pending-review sentence, and the calibration fields stay.

## skills/zspec/SKILL.md

- Kept: the whole file (15 lines).
- Cut: none.
- Replaced with a check: none.
- Why: The file is short. The citation line is a constraint (inline code, a path from the repo root) and a workflow step (`scripts/check-repo-paths.sh`, stop when it exits non-zero). The script reports a bad path. It does not tell the author to run it.

## skills/zstack/SKILL.md

- Kept: the whole file (177 lines).
- Cut: none.
- Replaced with a check: none.
- Why: This change does not edit that file. `scripts/check.sh` greps exact sentences through it. A trim would drop a workflow step or fail the check.

## skills/ztickets/SKILL.md

- Kept: the whole file (15 lines).
- Cut: none.
- Replaced with a check: none.
- Why: The file is short. Every line is a trigger, an output path, a ban on publishing, or the slice-count rule from Classify. No check encodes that count.
