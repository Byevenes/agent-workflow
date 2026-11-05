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

`to-analysis` → questions to the TL/PO (`to-questionnaire`) → Brayan pastes the answers in `.scratch/answers.md` (Jira and Confluence are read-only: never comment, edit or transition) → `grill-with-docs` if gaps remain → `to-techspec` → then the normal size path (Small/Medium/Large/Critical). The TechSpec accompanies the user story as input for the spec. External PRD/TD documents are optional, only when the client asks for them.

Client KDBs (mandatory in every client task, HU or not). Read `~/.config/zstack/clients.toml` (contract: `docs/examples/clients.toml.example`). Pick the client whose `root` is a prefix of the worktree path. From its `kdb_dir`, read the KDBs that apply to the task (skip `exclude`; `team_lessons` is local team notes, read them, never send them to an external tool). If `confluence_guidelines` is set, read that page (read-only). Right under the classification line, write `kdb: <files read>`, or `kdb: none found (<reason>)` when there is no map, no matching root, or no KDB applies. A matching root with no `kdb:` line is a violation. Pass the same paths to zNinja and zSensei.

If `to-analysis`, `to-questionnaire` or `to-techspec` is missing, stop and tell Brayan (`scripts/setup-check.sh` reports them). Attachments: Brayan downloads them by hand into the task folder; read them there, never fetch them with API tokens. Client work happens with the company worktree tool from PATH (or a path defined only in local config); Brayan must approve the worktree before use.

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

Say the size, verifiability, and reason in one line before anything else: `zstack: <size>, <full|partial> verifiable — <reason>`, size one of Small, Medium, Large, Critical. `route-audit.sh` fails a session without it. The old prefix `route-work:` is still accepted until 2026-12-01.

## 2. Plan (before code)

- **Small.** `zgrill` (grill-me) only if a decision is still open, one question at a time. No spec.
- **Medium.** `zgrill` (grill-with-docs). It must ask "where does the state live?" for every piece of state the change touches. End the grill with an `in-your-own-words` restatement the user confirms, then `zspec` (to-spec), written to `.scratch/<slug>.md` (disposable, not committed unless the repo asks). Optional: an ADR in `docs/adr/` when a decision is hard to reverse; a statechart (mermaid `stateDiagram-v2`) in the spec when the feature has several states. Medium runs full-spec mode (`implement-spec`) in one session, with no slices.
- **Large.** Medium, plus `ztickets` (to-tickets, slices), then **stop for the user's approval before any code**. If the user already approved the whole run in writing, quote that approval and continue. Use `wayfinder` when the plan does not fit one session.
- **Critical.** Large, plus `security-and-hardening` in the spec. `formal-verification` is optional for invariants.

Optional statechart (Medium and up). Trigger: the change has states, retries, or concurrency. After the spec and before code, next to `blast-radius`, ask "find all of the implicit state machines" and feed the answer to `statechart`. Personal repos: run it. Client repos: read-only analysis, the model lives only in `.scratch/`, and only with Brayan's approval.

Sandcastle is a reference for sandboxed runs, not a dependency. `zgrill`, `zspec`, `ztickets` and `tdd` must stay model-invocable. If a wrapper reports Matt's file missing, stop and ask the user to run `/<skill>` by hand. `scripts/setup-check.sh` reports both.

If a medium or large change turns out to cross a critical boundary, reclassify it as critical and continue from there.

## 3. Implement (subagent, or inline)

Launch the `zninja` subagent with the Task tool (`subagent_type: "zninja"`) for every size, including small. Pass: the task or spec path, the repo and branch, the size, the checks to run, the paths it must not touch, whether to commit (client repos: the slice commit rules in section 5), and the `kdb:` paths from section 0 (client tasks). Do not edit files in this chat on that path.

Run inline when the Task tool is absent, or its subagent list does not include zninja, or one launch attempt returned an error (quote it in the reason), or this session is a whole task that arrived with no parent and is running headless without subagents; if the Task tool exists and lists zninja, you must launch it. Medium, Large and Critical: code is written by zNinja; inline only in Small with `inline: <razón>` (if zninja cannot launch on Medium+, stop and tell Brayan).

Inline: read `poteto-mode` by the path in the intro and follow it. Load the skills for this size (`tdd`, `pstack-tdd` on OpenCode, `security-and-hardening` on critical). Emit the zninja report lines (`poteto-mode: loaded`, `size:`, `checks:`) and the zstack check block. Set `zninja launched: no (inline: <reason>)`.

- Small: the task. One focused test if behavior changes.
- Medium and up: the spec path. `poteto-mode` with pstack's `tdd` (`pstack-tdd` on OpenCode).
- Large and critical: a new `zninja` per slice, in order, each in a fresh context.
- Critical: tell it to apply `security-and-hardening`. Inline: apply it here.

On the subagent path, reject the report if it lacks the line `poteto-mode: loaded`. Relaunch it once with that requirement explicit. On the inline path, include that line in this session's report.

## 4. Check (after code)

Review follows the size, not the path (decision: option B). On the inline path, Small gets a second author pass (`reviewers: inline self-check`). Medium, Large and Critical (always zNinja) get `zsensei` exactly as below. If zsensei cannot be launched, set `reviewers: none (zsensei unavailable: <reason>)` and do not open the PR until Brayan reviews it.

- **Small.** Read the diff and the checks it ran. No review agent.
- **Medium.** `zsensei` on the diff, with the spec path. It must confirm the spec still matches the diff.
- **Large.** `blast-radius`, then `zsensei` with the spec and tickets.

Prefer automatic barriers (lint, checks, hooks, CI) over more skill text. Each repo should have its own verification skill (`create-verification-skill`, then `verify-<app>`). Client repos: only the checks they already have, and the verification skill lives locally outside the repo.

`zsensei` always reads the test diff: only new green tests mean new behavior; modified or deleted tests mean changed behavior and get extra scrutiny.
- **Critical.** `zsensei`, then `security-auditor`.

## 5. Deliver and retro

Delivery report: **summary**, **evidence** (what ran and its real result), **what can break** (from `blast-radius`). PR or MR description (decision #16): always use the `zpr` skill. Personal repos: every PR body follows zpr, and CI checks its headings. Client repos (the clients root from local config, `$CLIENTS_ROOT/**`, GitLab client MRs): zpr writes a suggested body for Brayan in `.scratch/pr-body.md`; never post it. Before writing to `.scratch/` in a client worktree, add `.scratch/` to `$(git rev-parse --git-path info/exclude)` so it never shows in `git status` (`scripts/setup-check.sh` reports it).

Merge: only Brayan merges, and only on his explicit order, in every repo. Never merge, enable auto-merge, or merge a PR yourself as a shortcut. Client repos: never `--force`, no push, MR or PR without Brayan's explicit order, stay inside the task worktree, and every step needs his approval except the local slice commit below.

Client slice commits (local only). Normal flow is a loop per slice: slice done → commit gate → local commit → log in `.scratch/commits.md` → next slice. No extra ok: the slices were approved before code, each slice is one commit, and its message comes from the slice's issue. If the slice's scope changed from what was approved, do not commit: stop and tell Brayan. Recovery case: if, when the gate starts, uncommitted changes span more than one slice (or mix slices in one file), stop, show Brayan the commit plan (commits, files or hunks, messages) and wait for his ok before the first commit. Check detection (technology-agnostic), by priority: 1) the client KDB or `commit_checks` / `push_checks` in `clients.toml`; 2) what the repo already defines (package.json scripts, Makefile, `.sln`/`.csproj`, pyproject/tox, `go.mod`, `Cargo.toml`, `.pre-commit-config.yaml`; CI config as a reference for what the pipeline runs). Never invent checks: if none is found, do not commit, tell Brayan. Never install anything in a client repo: no hooks, no `core.hooksPath`, no new `.husky/`, `.githooks/` or pre-commit config.

Commit gate (light, every slice), in order; any failure means no commit: report the step and its real output, and stop.
1. Format and lint, only if the repo already uses them.
2. Fast compile or type check (incremental when the tool allows it).
3. Only the slice's tests (the ones TDD already runs).
4. Existing pre-commit hooks run as they are; never use `--no-verify` or `CLIENT_PUSH_OK`. If one (including the opt-in `client-guard/pre-commit`) blocks, stop and tell Brayan.
5. Stage explicitly only the slice's files (`git add <paths>`, `git add -p` when a file mixes slices; never `git add -A` or `git add .`), then read `git diff --cached`: no secrets, no `.scratch/`, `.atl/` or config the KDB forbids, no stray debug output or new loose TODOs, no files outside the slice.
6. Identity and convention: if the client entry in `clients.toml` has `git_email`, `git config user.email` must equal it; without it, abort when the email looks personal (`@gmail.com`, `@users.noreply.github.com`, `@hotmail.com`, `@outlook.com`, `@icloud.com`). Never change git config to fix it. The message follows the project or KDB convention.

Pre-push gate (full), before asking Brayan for the push order: clean build; full test suite, plus coverage when a threshold exists; existing pre-push hooks; review every commit of the branch against its base (identity, message convention, the KDB's file limit per MR if it sets one). A failure is fixed with a new commit; local amend or rebase only with Brayan's ok. Push still needs his explicit order.

After each gate, append to `.scratch/commits.md`: slice, commit hash, each check with its command, where it came from (KDB, clients.toml or repo file) and its real result.

Still only on Brayan's explicit order: push, MR or PR, merge, rebase, reset, amend, cherry-pick, `--force`, git config changes and hook installs.

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

Before reporting done, run `scripts/route-audit.sh` from this repo (Byevenes/agent-workflow). It counts most of the same facts (not verifiability) from Cursor transcripts and exits non-zero when a session edited inline without a reason, a Medium+ session edited without zsensei, or a Medium+ session edited without launching zninja (`medium+ inline`). A non-zero exit is a retro input, not something to explain away.
