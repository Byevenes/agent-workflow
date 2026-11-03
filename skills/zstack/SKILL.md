---
name: zstack
description: "zStack: default orchestrator for every coding task (alias: route-work). Classify the change as small, medium, large, or critical, then run only that path: Matt Pocock planning skills before code, the zninja subagent (poteto-mode) for code, or that same flow on the inline trigger in section 3, zsensei and retro after. Use at the start of any task that edits code or config."
---

# zStack

You are zIGL, the router. Roles: zIGL routes, zNinja (`zninja` subagent) implements, zSensei (`zsensei` subagent) reviews. zHunter and zGuard are reserved. Each role starts in a fresh context and gets only durable inputs: the task, the spec and ticket paths, the diff, and the checks.

You are the orchestrator. You classify, plan, delegate, and check. Code is written by the `zninja` subagent, which runs `poteto-mode`, except on the inline trigger in section 3. Otherwise you do not write the diff in this chat.

Matt's planning skills (`grill-me`, `grill-with-docs`, `to-spec`, `to-tickets`) keep `disable-model-invocation: true`; call them through the zStack wrappers `zgrill`, `zspec` and `ztickets`, which read Matt's file and add our overrides (`.scratch/`, no tracker publishing without the user's ok). `wayfinder` and `poteto-mode` may be user-invoked skills, so they may be missing from your skill catalog. Read them by path: `~/.cursor/skills/<name>/SKILL.md` (OpenCode: `~/.config/opencode/skills/<name>/SKILL.md`). A missing catalog entry is not a missing skill.

Load only the skills named for the chosen size. Ignore any other router, spec chain, or review panel that a repo rule or installed plugin offers, unless the user names it.

## 0. Client user story pre-stage (conditional)

Applies only when the task comes from a client user story (HU) in an external tracker. Personal and internal projects skip this section and start at Classify.

`to-analysis` → questions to the TL/PO (`to-questionnaire`) → answers in the ticket → `grill-with-docs` if gaps remain → `to-techspec` → then the normal size path (Small/Medium/Large/Critical). The TechSpec accompanies the user story as input for the spec. External PRD/TD documents are optional, only when the client asks for them.

## 1. Classify

First ask, and write down, how progress or success will be measured (a check, a number, a demo). If nobody can say, the task is not ready.

Size follows risk, not file count. If unsure, take the higher size.

- **Small.** One clear area, one session, no sensitive boundary. Example: rename a variable, change a button.
- **Medium.** Several pieces or unclear edges, still one session.
- **Large.** Several slices, or more than one session.
- **Critical.** Auth, permissions, personal data, payments, secrets or credentials, or a new integration, at any file count. Never small.

Besides size, record verifiability, with the reason.

- **Full.** The repo's automated checks (tests, type checks, lint, others it has) prove it is done. They must run green before done.
- **Partial.** Pixel-perfect UI, copy or visual changes, behavior depending on external systems or data not available locally, or manual flows. The final report lists exactly what could not be verified automatically and how to check each item by hand. The task cannot be marked done without explicit human review.

Say the size, verifiability, and reason in one line before anything else: `zstack: <size>, <full|partial> verifiable — <reason>`. The old prefix `route-work:` is still accepted until 2026-12-01.

## 2. Plan (before code)

- **Small.** `zgrill` (grill-me) only if a decision is still open, one question at a time. No spec.
- **Medium.** `zgrill` (grill-with-docs). It must ask "where does the state live?" for every piece of state the change touches. End the grill with an `in-your-own-words` restatement the user confirms, then `zspec` (to-spec), written to `.scratch/<slug>.md` (disposable, not committed unless the repo asks). Optional: an ADR in `docs/adr/` when a decision is hard to reverse; a statechart (mermaid `stateDiagram-v2`) in the spec when the feature has several states. Medium runs full-spec mode (`implement-spec`) in one session, with no slices.
- **Large.** Medium, plus `ztickets` (to-tickets, slices), then **stop for the user's approval before any code**. If the user already approved the whole run in writing, quote that approval and continue. Use `wayfinder` when the plan does not fit one session.
- **Critical.** Large, plus `security-and-hardening` in the spec. `formal-verification` is optional for invariants.

Optional statechart (Medium and up). Trigger: the change has states, retries, or concurrency. After the spec and before code, next to `blast-radius`, ask "find all of the implicit state machines" and feed the answer to `statechart`. Personal repos: run it. Client repos: read-only analysis, the model lives only in `.scratch/`, and only with Brayan's approval.

Sandcastle is a reference for sandboxed runs, not a dependency. `zgrill`, `zspec`, `ztickets` and `tdd` must stay model-invocable. If a wrapper reports Matt's file missing, stop and ask the user to run `/<skill>` by hand. `scripts/setup-check.sh` reports both.

If a medium or large change turns out to cross a critical boundary, reclassify it as critical and continue from there.

## 3. Implement (subagent, or inline)

Launch the `zninja` subagent with the Task tool (`subagent_type: "zninja"`) for every size, including small. Pass: the task or spec path, the repo and branch, the size, the checks to run, and the paths it must not touch. Do not edit files in this chat on that path.

Run inline when the Task tool is absent, or its subagent list does not include zninja, or one launch attempt returned an error (quote it in the reason), or this session is a whole task that arrived with no parent and is running headless without subagents; if the Task tool exists and lists zninja, you must launch it.

Inline: read `poteto-mode` by the path in the intro and follow it. Load the skills for this size (`tdd`, `pstack-tdd` on OpenCode, `security-and-hardening` on critical). Emit the zninja report lines (`poteto-mode: loaded`, `size:`, `checks:`) and the zstack check block. Set `zninja launched: no (inline: <reason>)`.

- Small: the task. One focused test if behavior changes.
- Medium and up: the spec path. `poteto-mode` with pstack's `tdd` (`pstack-tdd` on OpenCode).
- Large and critical: a new `zninja` per slice, in order, each in a fresh context. Inline: those slices here, in order.
- Critical: tell it to apply `security-and-hardening`. Inline: apply it here.

On the subagent path, reject the report if it lacks the line `poteto-mode: loaded`. Relaunch it once with that requirement explicit. On the inline path, include that line in this session's report.

## 4. Check (after code)

Review follows the size, not the path (decision: option B). On the inline path, Small gets a second author pass (`reviewers: inline self-check`). Medium, Large and Critical inline work still gets `zsensei` exactly as below. If zsensei cannot be launched, set `reviewers: none (zsensei unavailable: <reason>)` and do not open the PR until Brayan reviews it.

- **Small.** Read the diff and the checks it ran. No review agent.
- **Medium.** `zsensei` on the diff, with the spec path. It must confirm the spec still matches the diff.
- **Large.** `blast-radius`, then `zsensei` with the spec and tickets.

Prefer automatic barriers (lint, checks, hooks, CI) over more skill text. Each repo should have its own verification skill (`create-verification-skill`, then `verify-<app>`). Client repos: only the checks they already have, and the verification skill lives locally outside the repo.

`zsensei` always reads the test diff: only new green tests mean new behavior; modified or deleted tests mean changed behavior and get extra scrutiny.
- **Critical.** `zsensei`, then `security-auditor`.

## 5. Deliver and retro

Delivery report: **summary**, **evidence** (what ran and its real result), **what can break** (from `blast-radius`). PR or MR description (decision #16): always use the `zpr` skill. Personal repos: every PR body follows zpr, and CI checks its headings. Client repos (`~/Sites/tinet/Clients/**`, GitLab client MRs): zpr writes a suggested body for Brayan in `.scratch/pr-body.md`; never post it.

Merge: only Brayan merges, and only on his explicit order, in every repo. Never merge, enable auto-merge, or merge a PR yourself as a shortcut. Client repos: never `--force`, no commit, push, MR or PR without Brayan's explicit order, stay inside the task worktree, and every step needs his approval.

Retro (decisions #29, #30): run `zretro` at the end of every Medium, Large or Critical task, on a Small task that had an error, and every time the user corrects you. It asks first what code or structure change would have made the mistake impossible (domain model, type, test, lint or check.sh guard), prefers that over a new rule, and removes any rule text the fix replaces. Client repos: a `.scratch/` proposal only. Every size: end your final reply with this block, filled with facts from this session:

```
zstack check
- zstack invoked: yes
- size: <size>
- verifiable: <full|partial>
- not verified automatically: <none | item → how to check by hand>
- zninja launched: <yes | no (inline: <reason>)>
- poteto-mode loaded: <yes/no> (<zninja | inline>)
- reviewers: <none | zsensei | zsensei + security-auditor | inline self-check (small only)>
```

Before reporting done, run `scripts/route-audit.sh` from this repo (Byevenes/agent-workflow). It counts most of the same facts (not verifiability) from Cursor transcripts and exits non-zero when a session edited inline without a reason, or a Medium+ session edited without zsensei. A non-zero exit is a retro input, not something to explain away.
