# Workflow

Size picks the path. Risk outranks file count. Auth, permissions, personal data, payments, a new secret or credential, or a new integration is critical at any file count.

`skills/zstack` classifies and calls only that path, and is always on through `rules/zstack.mdc`. Code is written by the `zninja` subagent with `poteto-mode`. The inline trigger is in section 3 of `skills/zstack/SKILL.md`. Full map: `docs/software-factory.md`. On OpenCode, Sisyphus may split a large change, and it follows the same skill. It does not open the other installed routers. This repo does not rewrite Sisyphus on disk.

Engineer Lead, on the outer loop, can split work before it arrives. It does not implement. Dr Eggbot designs bots and stays outside this chain.

## How a change moves

```mermaid
flowchart TD
  intake[Intake] --> size{Size by risk}
  size -->|one area, no sensitive boundary| smallPath[zninja with poteto-mode and a focused test]
  size -->|several pieces, one session| medPath[zgrill then zspec then poteto-mode then one zsensei]
  size -->|several slices or more than one session| largePath[wayfinder zspec ztickets then slices then one zsensei]
  size -->|sensitive boundary| critPath[spec then poteto-mode then zsensei then security-auditor]
```

A sensitive boundary is critical at any file count. It does not re-enter the medium or large stop checks.

```mermaid
sequenceDiagram
  participant You
  participant Router as zstack
  participant Impl as zninja
  participant Review as zsensei
  participant Audit as security-auditor

  You->>Router: task
  alt Small
    Router->>Impl: task, no spec
    Impl-->>You: change and a focused test
  else Medium or large
    Router->>Router: zgrill and zspec
    Router->>Impl: spec
    Impl-->>Review: diff
    Review-->>You: one review
  else Critical
    Router->>Router: zgrill and zspec
    Router->>Impl: spec plus security-and-hardening
    Impl-->>Review: diff
    Review->>Audit: after the review
    Audit-->>You: security pass
  end
```

Inline runs skip the Router->>Impl handoff.

## Paths

- **Small.** One clear area, one session, no sensitive boundary. `zgrill` (grill-me) only if a decision is open. Then `zninja` with `poteto-mode`. A focused test if behavior changes. No spec. No PRD, Figma, or Stitch unless the user points at one. No `zsensei`, no `security-auditor`.
- **Medium.** Several pieces, one session, and none of the critical boundaries. `zgrill` (grill-with-docs), then `zspec` (to-spec). `prd-td-coherence` only when a PRD and a design already exist. `poteto-mode` with pstack's `tdd`. `zsensei` loads `code-review-and-quality` once. `retro` once. Read a visual reference only when one exists.
- **Large.** Several slices or more than one session, and none of the critical boundaries. `zgrill` or `wayfinder`, then `zspec` and `ztickets`. A human gate before code. Slices go to `zninja`. Then `blast-radius`, the same `zsensei`, and `retro`.
- **Critical.** Auth, permissions, personal data, payments, a new secret or credential, or a new integration, at any file count. Its own sequence: `zgrill`, `zspec`, `poteto-mode` with `security-and-hardening`, `zsensei`, then `security-auditor`. It does not stop at the medium or large boundary check.

## Examples

A button label change is small. The task is already clear, so `grill-me` is skipped. `poteto-mode` edits it. No spec and no review agent.

A one-session feature with two states and an unclear empty case is medium. `grill-with-docs` settles the empty case, `to-spec` writes it down, `poteto-mode` builds it, and `zsensei` reads the diff.

A change that stores a new personal-data field is critical whether it is a few lines or several files. It follows the critical sequence: a spec, `poteto-mode`, `zsensei`, then `security-auditor`.

## Not loaded

Installed skills and agents that this path does not call stay on disk. Other repos may still name them. The list is in `docs/value-review.md`.
