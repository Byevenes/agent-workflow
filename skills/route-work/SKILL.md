---
name: route-work
description: "Classify a change as small, medium, large, or critical, then call only that path. Use when starting work in this workflow stack."
disable-model-invocation: true
---

# Route work

Do not implement in this skill. Classify, then call the other skills. Do not load a skill this file does not name for the chosen size.

Size follows risk, not file count. Auth, permissions, personal data, payments, or a new integration is critical at any file count. It is never small and it is never left on medium or large.

## Classify

- **Small.** One clear area, one session, no sensitive boundary. Example: change a button.
- **Medium.** Several pieces or unclear edges, still one session, and none of the boundaries above.
- **Large.** Several slices, or more than one session, and none of the boundaries above.
- **Critical.** Any of those boundaries, short or long. Run the medium or large path that fits the rest of the change, then `security-auditor`. A short auth change is critical. A several-file personal-data change is critical.

If the size is unclear, treat it as the higher one.

## Small

1. Call `grill-me` only when a decision is still open. Skip it when the change is already clear.
2. Do not call `grill-with-docs`, `to-spec`, `to-tickets`, `wayfinder`, or `prd-td-coherence`.
3. Do not read a PRD, Figma, or Stitch unless the user points at one.
4. Hand the task to `implementer`. There is no spec. `poteto-mode` implements. If behavior changes, one focused test.
5. Do not call `code-review`, `code-reviewer`, `security-auditor`, or `test-engineer`.

## Medium

1. Call `grill-with-docs`.
2. Call `to-spec`. Publish the spec to this repo's issue tracker (`.scratch/`) when the work is in this repo. Otherwise publish it where the user said.
3. Call `prd-td-coherence` only when a PRD and a design already exist.
4. Read a PRD, Figma, or Stitch reference only when one already exists.
5. Hand the spec to `implementer`. `poteto-mode` implements, with pstack's `tdd`. On OpenCode that skill is `pstack-tdd` when the plain `tdd` name is Matt's.
6. Call `security-and-hardening` only inside that implementation, and only when the change touches input or a session that is not one of the critical boundaries. If it touches auth, permissions, personal data, payments, or a new integration, stop and treat the change as critical.
7. After the check passes, hand the diff to `code-reviewer`. That agent loads `code-review-and-quality`. Do not also call Matt's `code-review`.
8. Call `retro` once.

## Large

1. Call `grill-with-docs`. If it does not fit one session, call `wayfinder` instead of holding it all there.
2. Call `to-spec`, then `to-tickets`.
3. Call `prd-td-coherence` only when a PRD and a design already exist. Do not call `tech-lead`.
4. Stop for a human gate before code.
5. If the change touches auth, permissions, personal data, payments, or a new integration, stop and treat it as critical before any slice is implemented.
6. Hand each slice to `implementer` with `poteto-mode` and pstack's `tdd`.
7. After the slices pass, call `blast-radius`, then `code-reviewer` with `code-review-and-quality`. Do not call Matt's `code-review`.
8. Call `retro` once.
9. On OpenCode, Sisyphus may split the slices. It follows this skill. It does not open Hephaestus, Prometheus, Atlas, Gentleman, or the SDD chain. On Cursor, `coordinator` splits them.

## Critical

Auth, permissions, personal data, payments, or a new integration is this size at any file count. Run the medium or large path that fits, including `to-spec` before code and `security-and-hardening` during implementation. Add `security-auditor` after `code-reviewer`. `code-reviewer` may also ask for `security-auditor` when a finding needs that pass. Do not run `security-auditor` on a small change.

## Never on this path

Do not call these, even though they may be installed: `sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`, `sdd-verify`, `tech-lead`, `senior-code-engineer`, `test-engineer`, `interrogate`, `review-risk`, `review-readability`, `review-reliability`, `review-resilience`, `review-refuter`, `judgment-day`.

`interrogate` runs only when the user asks for a contested design. `test-engineer` runs only when the user asks for a test strategy, not because tests exist.

Do not write domain docs, skills, or rules into any repo other than this one unless the user says to write them there.
