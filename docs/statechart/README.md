# zStack statechart (TLA+ pilot, decision #23)

Model of the zStack flow in `skills/zstack/SKILL.md` at `d447961`, checked with TLC through pstack's `/statechart` skill.

| File | What |
|---|---|
| `ZStack.tla` | The model: one action per step in the skill, plus `EditInlineNoReason` (forbidden by the skill, not blocked by anything; route-audit saw it in 13 of 19 editing sessions). |
| `ZStack.cfg` | The six rules checked as invariants. |
| `view.mjs` | Labels for the chart (`/statechart --view`). |
| `chart.mmd` | Mermaid chart TLC drew (133 model states, 28 chart states). |
| `report.md` | TLC's report: which rules break and the shortest path for each. |

## Rules

| Rule | Plain sentence | Result |
|---|---|---|
| `NoEditBeforeClassify` | No file is edited before zStack prints the size. | holds |
| `BigNeedsApproval` | Large and Critical never get code before Brayan approves the plan. | holds (fails when the approval guard is removed) |
| `EditNeedsZninjaOrReason` | Every edit comes from zNinja or has `inline: <reason>`. | **breaks**: plan → agent codes inline without a reason |
| `MediumUpIndependentReview` | Medium and up never reach a PR without zSensei. | **breaks**: the skill itself sends inline work to "inline self-check" |
| `ClientNeverPublishes` | A client repo never gets a PR posted by the agent. | holds |
| `OnlyBrayanMerges` | Only Brayan merges. | **breaks**: section 5 allows automerge of a pure refactor in personal repos |

## Left out

The model checks the skill text, not the agent. It does not prove any session followed it, and it drifts when `skills/zstack/SKILL.md` changes. Not modeled: section 0 (client HU pre-stage), slices per ticket, reclassification to Critical, retries of a zninja launch, failing checks.

## Run again

Load the pstack `/statechart` skill and run its command on `ZStack.tla` with `--config ZStack.cfg --view view.mjs --out <new folder>`. It needs Java 11+ and `tla2tools.jar` (v1.7.4); without mise, set `TLA2TOOLS` and `JAVA`. A run takes about 4 s.
