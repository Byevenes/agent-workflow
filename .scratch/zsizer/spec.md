# zsizer

Status: ready-for-agent

## Problem Statement

Classify picks Small, Medium, Large, or Critical from risk and from whether the work fits one session. It does not count tokens. A Medium that was called "one session" can pass the session budget and degrade without going through `ztickets`.

## Solution

Risk still picks the process. Tokens pick how many tickets. The formula and the Medium promote live in Classify. `ztickets` slices into that count. Critical keeps the security path when the count is 1. Closing a task records the estimate next to the real token count.

## User Stories

1. As zIGL, I want risk to keep picking Small, Medium, Large, or Critical, so that a token count does not replace the process.
2. As zIGL, I want to write `tokens_estimados` and `holgura` before the size line, so that the ticket count has both inputs.
3. As zIGL, I want the task to stay unready when either number is missing, so that I do not invent a slack factor.
4. As zIGL, I want `tickets = ceil(tokens_estimados * holgura / 150_000)`, so that the session budget is 150_000 tokens.
5. As zIGL, I want a Medium whose estimate is about 150k tokens to promote to Large, so that it enters `ztickets` before the agent degrades.
6. As zIGL, I want the size line to use the printed size, so that the path matches the promote.
7. As zIGL, I want a Small to stay Small, so that the promote applies to Medium.
8. As zIGL, I want Critical to keep the security path when the ticket count is 1, so that one ticket does not skip `security-and-hardening` or `security-auditor`.
9. As zIGL, I want Critical to stay on the Large path plus security, so that one ticket does not remove the approval gate.
10. As ztickets, I want the slice count to be the ticket count from Classify, so that I do not estimate a second count.
11. As ztickets, I want each slice to fit one session of that budget, so that a slice stays inside the budget the formula used.
12. As zretro, I want to write `.scratch/<slug>/calibracion.md` at close, so that estimated and real tokens have one file.
13. As a reviewer, I want that file to hold tokens_estimados, holgura, tickets, tokens_reales, the size by risk, and the printed size, so that calibration has a fixed shape.
14. As a reviewer, I want `scripts/check.sh` to fail when the formula, the Medium promote, or the Critical security sentence is missing from Classify, so that the rule cannot vanish in prose.
15. As a reviewer, I want the same check to fail when the calibration path is missing from zstack or zretro, so that the log has one named place.
16. As a maintainer, I want the formula in one skill, so that a second copy cannot drift.
17. As a maintainer, I want the change to stay in this repo, so that there is no separate package.

## Implementation Decisions

- The formula, the Medium promote, and the Critical security sentence are in section 1 of the zstack skill. That is the source. `ztickets` points at that section and uses the count. It does not restate the formula.
- Holgura has no numeric default. The estimator supplies it.
- The promote sentence uses "about 150k tokens". It does not define whether holgura sits inside that comparison. That fork is in `.scratch/decisiones.md`.
- A Small stays Small. The issue names the promote for Medium.
- Critical with one ticket keeps the security path. It also stays on the existing Critical path, which is the Large path plus security. The ticket count does not remove the approval gate.
- The calibration file is `.scratch/<slug>/calibracion.md`. zstack section 5 names the fields. zretro writes the file at close.
- State lives in that file and in the classification line. There is no new config and no new store.
- The TLA+ model is unchanged. Promote happens inside Classify, before the size the model reads is set.
- Progress is `scripts/check.sh` exiting 0. The check greps the formula, the promote sentence, the Critical sentence, and the calibration path.

## Testing Decisions

- The seam is `scripts/check.sh`. It is the public check this repo already runs.
- A good test fails when one of those sentences is absent and passes when the sentences are present. It does not parse a private helper.
- Prior art is the other `grep -qF` content checks in `scripts/check.sh`.
- There is no executable `ceil`. A calculator would decide the open 150k comparison.

## Out of Scope

- A separate `zsizer` skill. Recorded as an option, not built.
- A numeric default for holgura.
- A strict reading of "about 150k" as raw tokens or as the padded product.
- Promoting Small when the estimate is large.
- Editing the TLA+ model or running TLC.
- Changing the review role, route-audit, push, or a pull request.

## Further Notes

Where the state lives: `.scratch/<slug>/calibracion.md` for the estimate and the real count. The printed size lives on the classification line.

How progress and success are measured: `scripts/check.sh` is green, including the new greps.
