# Retro 2026-11-16: client pre-stage, QA handoff and VPN test run

Three working days on one client ticket pair: analysis → questionnaire → TechSpec, an API collection export for a QA colleague, then a full local test run once the client network was reachable. Medium, partial verifiable (remote services and a shared database).

## What helped

- The pre-stage order held: the questionnaire closed the open points before the TechSpec, and the answers went straight into it.
- Read-only database checks on the client network settled one open question (a template type value) with evidence instead of a guess.
- Each worktree had local commits per slice, so the full run after reconnecting had a clean base to compare against.

## Friction

- **A full test suite reached a remote service and caused a real side effect.** One existing test in the repo calls a remote endpoint that sends a verification message to a fixed recipient. It passed, so the message most likely went out. The suite was run whole because nothing marked which tests leave the machine.
- **A TechSpec called a column required without checking it.** The read-only schema query showed the column accepts nulls. The claim had been written from the domain model, not from the schema.
- **The export for QA needed a hand review for secrets.** Environment files carry live tokens by default; nothing checked the package before it left the machine.
- **An input document for another tool pointed at local notes.** It had to be rewritten to stand alone.

## Turned into a barrier (decision 29)

| Error | Barrier |
| --- | --- |
| Remote test ran in a local gate | `scripts/check-remote-tests.sh` lists test files with a non-local URL or a configured HTTP client; zstack commit and pre-push gates exclude them and record them as not run; they run only on an explicit order |
| "Required" without schema evidence | `scripts/check-required-claims.sh` fails a required/not-null claim on a field or column without `fuente:`; `to-techspec` runs it |
| Secrets in a shared export | `scripts/check-export-package.sh` fails secret-like keys with set values and JWT-shaped values, then runs `gitleaks dir` |
| Input document not self-contained | zstack §5 runs `scripts/check-delivery-note.sh` on any document written as input for another tool or person |

## Left out

- `check-remote-tests.sh` is a heuristic. A test that reaches the network through a shared helper in another file is not seen. The next step, if it happens again, is a test category or trait the repo already supports, proposed to the repo owner.
- Building the runner's exclude filter from the list is per stack; it stays in the session, not in a script.
