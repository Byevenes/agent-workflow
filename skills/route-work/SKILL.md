---
name: route-work
description: "Default orchestrator for every coding task. Classify the change as small, medium, large, or critical, then run only that path: Matt Pocock planning skills before code, the implementer subagent (poteto-mode) for code, or that same flow on the inline trigger in section 3, code-reviewer and retro after. Use at the start of any task that edits code or config."
---

# Route work

You are the orchestrator. You classify, plan, delegate, and check. Code is written by the `implementer` subagent, which runs `poteto-mode`. Run inline when the Task tool is absent, or its subagent list does not include implementer, or one launch attempt returned an error (quote it in the reason), or this session is a whole task that arrived with no parent and is running headless without subagents; if the Task tool exists and lists implementer, you must launch it. Otherwise you do not write the diff in this chat.

Planning skills (`grill-me`, `grill-with-docs`, `to-spec`, `to-tickets`, `wayfinder`) and `poteto-mode` are user-invoked skills, so they may be missing from your skill catalog. Read them by path: `~/.cursor/skills/<name>/SKILL.md` (OpenCode: `~/.config/opencode/skills/<name>/SKILL.md`). A missing catalog entry is not a missing skill.

Load only the skills named for the chosen size. Ignore any other router, spec chain, or review panel that a repo rule or installed plugin offers, unless the user names it.

## 0. Client user story pre-stage (conditional)

Applies only when the task comes from a client user story (HU) in an external tracker. Personal and internal projects skip this section and start at Classify.

`to-analysis` → questions to the TL/PO (`to-questionnaire`) → answers in the ticket → `grill-with-docs` if gaps remain → `to-techspec` → then the normal size path (Small/Medium/Large/Critical). The TechSpec accompanies the user story as input for the spec. External PRD/TD documents are optional, only when the client asks for them.

## 1. Classify

Size follows risk, not file count. If unsure, take the higher size.

- **Small.** One clear area, one session, no sensitive boundary. Example: rename a variable, change a button.
- **Medium.** Several pieces or unclear edges, still one session.
- **Large.** Several slices, or more than one session.
- **Critical.** Auth, permissions, personal data, payments, secrets or credentials, or a new integration, at any file count. Never small.

Besides size, record verifiability, with the reason.

- **Full.** The repo's automated checks (tests, type checks, lint, others it has) prove it is done. They must run green before done.
- **Partial.** Pixel-perfect UI, copy or visual changes, behavior depending on external systems or data not available locally, or manual flows. The final report lists exactly what could not be verified automatically and how to check each item by hand. The task cannot be marked done without explicit human review.

Say the size, verifiability, and reason in one line before anything else: `route-work: <size>, <full|partial> verifiable — <reason>`.

## 2. Plan (before code)

- **Small.** `grill-me` only if a decision is still open, one question at a time. No spec.
- **Medium.** `grill-with-docs`. Then `to-spec`, written to `.scratch/<slug>.md` (disposable, not committed unless the repo asks). Optional: an ADR in `docs/adr/` when a decision is hard to reverse; a statechart (mermaid `stateDiagram-v2`) in the spec when the feature has several states.
- **Large.** Medium, plus `to-tickets` (slices), then **stop for the user's approval before any code**. Use `wayfinder` when the plan does not fit one session.
- **Critical.** Large, plus `security-and-hardening` in the spec. `formal-verification` is optional for invariants.

If a medium or large change turns out to cross a critical boundary, reclassify it as critical and continue from there.

## 3. Implement (subagent, or inline)

Launch the `implementer` subagent with the Task tool (`subagent_type: "implementer"`) for every size, including small. Pass: the task or spec path, the repo and branch, the size, the checks to run, and the paths it must not touch. Do not edit files in this chat on that path.

Run inline when the Task tool is absent, or its subagent list does not include implementer, or one launch attempt returned an error (quote it in the reason), or this session is a whole task that arrived with no parent and is running headless without subagents; if the Task tool exists and lists implementer, you must launch it.

Inline: read `poteto-mode` by the path in the intro and follow it. Load the skills for this size (`tdd`, `pstack-tdd` on OpenCode, `security-and-hardening` on critical). Emit the implementer report lines (`poteto-mode: loaded`, `size:`, `checks:`) and the route-work check block. Set `implementer launched: no (inline: <reason>)`.

- Small: the task. One focused test if behavior changes.
- Medium and up: the spec path. `poteto-mode` with pstack's `tdd` (`pstack-tdd` on OpenCode).
- Large and critical: one `implementer` per slice, in order. Inline: those slices here, in order.
- Critical: tell it to apply `security-and-hardening`. Inline: apply it here.

On the subagent path, reject the report if it lacks the line `poteto-mode: loaded`. Relaunch it once with that requirement explicit. On the inline path, include that line in this session's report.

## 4. Check (after code)

When section 3 ran inline, this pass is a second author pass, not the code-reviewer role. Do not launch a reviewer subagent on that path. Set `reviewers: inline self-check`.

- **Small.** Read the diff and the checks it ran. No review agent.
- **Medium.** `code-reviewer` on the diff, with the spec path. It must confirm the spec still matches the diff.
- **Large.** `blast-radius`, then `code-reviewer` with the spec and tickets.
- **Critical.** `code-reviewer`, then `security-auditor`.

## 5. Retro

Medium and up: run `retro` once. Every size: end your final reply with this block, filled with facts from this session:

```
route-work check
- route-work invoked: yes
- size: <size>
- verifiable: <full|partial>
- not verified automatically: <none | item → how to check by hand>
- implementer launched: <yes | no (inline: <reason>)>
- poteto-mode loaded: <yes/no> (<implementer | inline>)
- reviewers: <none | code-reviewer | code-reviewer + security-auditor | inline self-check>
```

`scripts/route-audit.sh` in the agent-workflow repo counts most of the same facts (not verifiability) from Cursor transcripts.
