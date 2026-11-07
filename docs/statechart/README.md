# zStack statechart (TLA+, decision #23)

Model of `skills/zstack/SKILL.md` after option B: large and critical get zSensei, small and medium get a light review, and only Brayan merges. Checked with TLC through pstack's `/statechart`.

Each forbidden step is a separate `Agent*` action, enabled only when its `Barrier*` constant is `FALSE`. `FALSE` means only skill text stops the step; `TRUE` means a hook, CI check or permission makes it impossible.

| File | What |
|---|---|
| `ZStack.tla` | The model: the skill's steps plus 6 forbidden agent steps. |
| `ZStackTextOnly.cfg` | All barriers `TRUE`: what the skill promises if the agent obeys it. |
| `ZStack.cfg` | All barriers `FALSE`: the repo today, where nothing blocks those steps. |
| `view.mjs` | Chart labels for `/statechart --view`. |
| `chart.mmd`, `report.md` | Run on `ZStackTextOnly.cfg` (94 states). |
| `chart-today.mmd`, `report-today.md` | Run on `ZStack.cfg` (347 states). |

## Rules

| Rule | Plain sentence | Agent obeys the text | Today (no barrier) | What exists today |
|---|---|---|---|---|
| `NoEditBeforeClassify` | No edit before the size is printed. | holds | breaks (1 step) | text only |
| `BigNeedsApproval` | Large/Critical never get code before Brayan approves. | holds | breaks | text only |
| `EditNeedsZninjaOrReason` | Every edit is zNinja or `inline: <reason>`. | holds | breaks (3 steps) | `route-audit.sh` exits 1 after the fact; does not block |
| `LargeCriticalIndependentReview` | Large or Critical never reaches a PR, merge, or client draft without zSensei. | holds | breaks (6 steps) | `route-audit.sh` detects after the fact; does not block |
| `ClientNeverPublishes` | The agent never posts a client PR/MR. | holds | breaks (6 steps) | text only |
| `OnlyBrayanMerges` | Only Brayan merges. | holds | breaks (7 steps) | text only; branch protection needs a green check but does not stop the agent's token from merging |

So every rule holds by text, none by a blocking barrier. The design is now consistent (no rule breaks when the text is obeyed, which was not true before option B).

## Left out

The model checks the skill text, not the agent's behavior or the code. It drifts when `skills/zstack/SKILL.md` changes. Not modeled: client HU pre-stage, slices, reclassification to Critical, failing checks or retries.

## Run again

Load pstack's `/statechart` and run it on `ZStack.tla` with `--config ZStackTextOnly.cfg` (or `ZStack.cfg`) `--view view.mjs --out <new folder>`. Needs Java 11+ and `tla2tools.jar` v1.7.4; without mise, set `TLA2TOOLS` and `JAVA`. CI (`.github/workflows/tla.yml`) runs plain TLC on `ZStackTextOnly.cfg` and must pass.

## With client-guard installed (`ZStackHooked.cfg`)

`BarrierClientPublish = TRUE` models `hooks/client-guard/pre-push` installed in every client repo: no branch reaches a client remote, so no client PR can open. TLC (272 states): `ClientNeverPublishes` and `NoDeadlock` hold; the other five rules still break exactly as in `ZStack.cfg`. CI checks `ClientNeverPublishes` with this config. It holds only after Brayan installs the hook, and `--no-verify` or `CLIENT_PUSH_OK=brayan` bypass it. `BarrierMerge` stays FALSE while the agent's token is Brayan's admin account.
