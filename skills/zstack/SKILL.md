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

### System map

At the start of `to-analysis`, before the detailed analysis, write a short system map. If that step already produces this map, keep one map and apply these rules there.

Name the affected modules, the boundaries between them, and the dependencies. List each branch to compare and why, or say none apply. Read the names from the repo or the task. Do not assume branch names.

Separate what was observed from what is still unconfirmed, and cite the source of each line. The map limits the later walk. It does not redesign the system. A short case is `docs/examples/system-map.md`.

Client KDBs (mandatory in every client task, HU or not). Read `~/.config/zstack/clients.toml` (contract: `docs/examples/clients.toml.example`). Pick the client whose `root` is a prefix of the worktree path. From its `kdb_dir`, read the KDBs that apply to the task (skip `exclude`; `team_lessons` is local team notes, read them, never send them to an external tool). If `confluence_guidelines` is set, read that page (read-only). Right under the classification line, write `kdb: <files read>`, or `kdb: none found (<reason>)` when there is no map, no matching root, or no KDB applies. A matching root with no `kdb:` line is a violation. Pass the same paths to zNinja and zSensei.

If `to-analysis`, `to-questionnaire` or `to-techspec` is missing, stop and tell Brayan (`scripts/setup-check.sh` reports them). Attachments: Brayan downloads them by hand into the task folder; read them there, never fetch them with API tokens. Client work happens with the company worktree tool from PATH (or a path defined only in local config); Brayan must approve the worktree before use.

## 1. Classify

First ask, and write down, how progress or success will be measured (a check, a number, a demo). If nobody can say, the task is not ready.

Size follows risk, not file count. If unsure, take the higher size.

- **Small.** One clear area, one session, no sensitive boundary. Example: rename a variable, change a button.
- **Medium.** Several pieces or unclear edges, still one session.
- **Large.** Several slices, or more than one session.
- **Critical.** Auth, permissions, personal data, payments, secrets or credentials, or a new integration, at any file count. Never small.

Risk picks the process. Tokens pick the ticket count. Before the size line, write `tokens_estimados` and `holgura`. The estimator supplies holgura. Both numbers are required. Then compute:

`tickets = ceil(tokens_estimados * holgura / 150_000)`

A Medium whose estimate is about 150k tokens promotes to Large and enters `ztickets`. Print the size after that promote. A Small stays Small. Critical stays Critical.

Critical keeps the security path even when the ticket count is 1.

Besides size, record verifiability, with the reason. On every task, ask how the change will be made fully verifiable. Record the answer as full or partial.

- **Full.** The repo's automated checks (tests, type checks, lint, others it has) prove it is done. They must run green before done. Record which automatic check covers the change.
- **Partial.** Pixel-perfect UI, copy or visual changes, behavior depending on external systems or data not available locally, or manual flows. The final report lists exactly what could not be verified automatically and how to check each item by hand. The task cannot be marked done without explicit human review. A partial answer blocks code until a written verification plan exists.

Say the size, verifiability, and reason in one line before anything else: `zstack: <size>, <full|partial> verifiable — <reason>`, size one of Small, Medium, Large, Critical. `route-audit.sh` fails a session without it. The old prefix `route-work:` is still accepted until 2026-12-01.

## 2. Plan (before code)

- **Small.** `zgrill` (grill-me) only if a decision is still open, one question at a time. No spec.
- **Medium.** `zgrill` (grill-with-docs). It must ask "where does the state live?" for every piece of state the change touches. End the grill with an `in-your-own-words` restatement the user confirms, then `zspec` (to-spec), written to `.scratch/<slug>.md` (disposable, not committed unless the repo asks). Optional: an ADR in `docs/adr/` when a decision is hard to reverse; a statechart (mermaid `stateDiagram-v2`) in the spec when the feature has several states. Medium runs full-spec mode (`implement-spec`) in one session, with no slices.
- **Large.** Medium, plus `ztickets` (to-tickets, slices), then **stop for the user's approval before any code**. If the user already approved the whole run in writing, quote that approval and continue. Use `wayfinder` when the plan does not fit one session. After approval, run the Slice loop below. A Medium that grows a second slice is promoted to Large and uses the same loop.
- **Critical.** Large, plus `security-and-hardening` in the spec. `formal-verification` is optional for invariants.

### Slice loop

Large, and a Medium promoted to Large. `ztickets` writes one vertical ticket per slice. Each ticket is one session. The state of a slice is that ticket file plus its commit. The previous session does not carry over.

1. Open a new session. Read that ticket, the spec path, and the checks.
2. Implement only that ticket.
3. Run the checks.
4. Local commit for that ticket. Client repos use section 5. Any other repo commits only when the user already ordered it.
5. Stop. The next ticket starts in a new session.

A recovery plan does not replace that new session. Use a recovery plan only when a check is red, or when the Recovery case in section 5 fires.

### Slice verification

Before the slice closes, run the same suite on the base branch and on HEAD, or reuse cached result files, and classify them with `scripts/classify-test-failures.sh`. A HEAD failure is env-known only when the same id and the same detail fail on the base branch. That class does not block the slice. A failure that is new or different on HEAD is real and blocks the slice. With no base result, every HEAD failure is real. Do not label it env-known.

Slice close, before the session ends:

- Checks for this ticket are green.
- The commit is only this ticket, and the message comes from it.
- An approved out-of-scope fix is already a `fix:` commit before this ticket's commit.
- The worktree has no leftover diff for a later ticket.
- The next ticket is not started here.

Example. Ticket A ends at its commit and the session stops. Ticket B opens in a new session. A note that says to continue with B in this chat is the failure mode.

Optional statechart (Medium and up). Trigger: the change has states, retries, or concurrency. After the spec and before code, next to `blast-radius`, ask "find all of the implicit state machines" and feed the answer to `statechart`. Personal repos: run it. Client repos: read-only analysis, the model lives only in `.scratch/`, and only with Brayan's approval.

Sandcastle is a reference for sandboxed runs, not a dependency. `zgrill`, `zspec`, `ztickets` and `tdd` must stay model-invocable. If a wrapper reports Matt's file missing, stop and ask the user to run `/<skill>` by hand. `scripts/setup-check.sh` reports both.

If a medium or large change turns out to cross a critical boundary, reclassify it as critical and continue from there.

## 3. Implement (subagent, or inline)

Launch the `zninja` subagent with the Task tool (`subagent_type: "zninja"`) for every size, including small. Pass: the task or spec path, the repo and branch, the size, the checks to run, the paths it must not touch, whether to commit (client repos: the slice commit rules in section 5), the `kdb:` paths from section 0 (client tasks), and the question of how the change will be made fully verifiable together with the recorded answer (full or partial). Do not edit files in this chat on that path.

Run inline when the Task tool is absent, or its subagent list does not include zninja, or one launch attempt returned an error (quote it in the reason), or this session is a whole task that arrived with no parent and is running headless without subagents; if the Task tool exists and lists zninja, you must launch it. Medium, Large and Critical: code is written by zNinja; inline only in Small with `inline: <razón>` (if zninja cannot launch on Medium+ and the host is Cursor, stop and tell Brayan).

Project agents (issue #58). Cursor CLI and Cloud Agents load `.cursor/agents/` from the repo. The IDE also reads `~/.cursor/agents`, which `scripts/link.sh` fills from the same files. This repo registers `zninja`, `zsensei`, and `zigl` in `.cursor/agents/` as relative symlinks to `agents/<name>.md`. `agents/zsensei.md` sets `model: claude-opus-5-5-medium` and `readonly: true`. Outside a clone, Cursor CLI loads `~/.cursor/plugins/local/zstack-agents/`, where `agents` is `./agents/`. `scripts/link.sh` copies the three agent files there as regular files, because symlinks in that folder do not load. Plugin loads ignore the `model` frontmatter, so the Task argument selects the model. `agents/zninja.md` sets no model, so the subagent inherits the parent, and its frontmatter must not name a `-fast` slug. When Task lists `zninja`, launch it. The inline trigger above covers a session whose Task list omits `zninja`.

Inline: read `poteto-mode` by the path in the intro and follow it. Load the skills for this size (`tdd`, `pstack-tdd` on OpenCode, `security-and-hardening` on critical). Emit the zninja report lines (`poteto-mode: loaded`, `size:`, `checks:`) and the zstack check block. Set `zninja launched: no (inline: <reason>)`.

- Small: the task. One focused test if behavior changes.
- Medium and up: the spec path. `poteto-mode` with pstack's `tdd` (`pstack-tdd` on OpenCode).
- Large and critical: a new `zninja` per slice, in order, each in a fresh context. That is the Slice loop. Do not keep the session and switch tickets under a recovery plan.
- Out-of-scope bug: stop and ask. The protocol is in `agents/zninja.md`. An approved fix is a `fix:` commit before the slice commit, never inside it.
- Critical: tell it to apply `security-and-hardening`. Inline: apply it here.

On the subagent path, reject the report if it lacks the line `poteto-mode: loaded`. Relaunch it once with that requirement explicit. On the inline path, include that line in this session's report.

### Inline without Cursor

Use this mode only when the host is not Cursor. If the Cursor Task tool lists zninja, launch zninja. This mode is not a bypass. The stop-and-tell for a missing zNinja on Medium and up applies when the host is Cursor. Outside Cursor this mode covers every size, including Medium and up.

Run `git push --dry-run` before coding starts when the branch has an upstream. When the branch has no upstream, run `git push --dry-run <remote> HEAD`. Either command must contact the remote. `git status` is not an equivalent. Stop before any edit when that dry-run is rejected, the remote is missing, or the dry-run fails. The dry-run does not push.

Outside Cursor, if zSensei cannot be launched, or if zNinja cannot be launched and this session writes the diff, a separate subagent or session reviews and receives only the diff. The author does not review their own diff. Record `reviewers: independent (no Cursor: <who>)`.

When a host that is not Cursor can still launch zNinja and zSensei, keep the size review in section 4. Still run the push dry-run.

## 4. Check (after code)

Review follows the size, not the path (decision: option B). On the inline path, Small gets a second author pass (`reviewers: inline self-check`). Medium, Large and Critical (always zNinja) get `zsensei` exactly as below. If zsensei cannot be launched, set `reviewers: none (zsensei unavailable: <reason>)` and do not open the PR until Brayan reviews it. On a host that is not Cursor, follow `### Inline without Cursor` instead. A separate reviewer receives only the diff. Plugin loads ignore the `model` frontmatter, so the Task argument selects the model. The review role never runs on another model.

- **Small.** Read the diff and the checks it ran. No review agent.
- **Medium.** `zsensei` on the diff, with the spec path. It must confirm the spec still matches the diff. Every Task call to zsensei passes model: claude-opus-5-5-medium.
- **Large.** `blast-radius` (`skills/blast-radius/SKILL.md`), then `zsensei` with the spec and tickets. That step runs `scripts/blast-radius-callers.sh`. The report lists every in-module caller, including private methods and indirect callers. The check fails when the report misses one. Every Task call to zsensei passes model: claude-opus-5-5-medium.

Prefer automatic barriers (lint, checks, hooks, CI) over more skill text. Each repo should have its own verification skill (`create-verification-skill`, then `verify-<app>`). Client repos: only the checks they already have, and the verification skill lives locally outside the repo.

### Commit-order gate

Classify decides whether a Large run requires `scripts/check-commit-order.sh`. The gate checks out every commit in `base..HEAD` in a temporary worktree and runs the command you pass. The base commit is excluded. The first red commit fails the gate and names that commit. It does not install hooks, and it does not change the caller's checkout.

`scripts/check-commit-order.sh <base> -- <command> [args...]`

Pass a check the repo already defines. Do not invent one. Run it from the repo root. The command's current directory is that commit's tree.

`zsensei` always reads the test diff: only new green tests mean new behavior; modified or deleted tests mean changed behavior and get extra scrutiny.
- **Critical.** `zsensei`, then `security-auditor`. Every Task call to zsensei passes model: claude-opus-5-5-medium.

## 5. Deliver and retro

Delivery report (one report, before the PR or delivery): **summary** (short pseudocode), **flow** (Mermaid; concurrency and interactions only when relevant; a diagram is not proof), **evidence** (commands that ran, with real results and limits; reuse pre-push evidence; never invent a run; a check that did not run stays explicit; tests and the TDD cycle when TDD was used), **what can break** (from `blast-radius`). Shape: `docs/examples/review-package.md`. PR or MR description (decision #16): always use the `zpr` skill. Personal repos: every PR body follows zpr, and CI checks its headings. Client repos (the clients root from local config, `$CLIENTS_ROOT/**`, GitLab client MRs): zpr writes a suggested body for Brayan in `.scratch/pr-body.md`; never post it. Before writing to `.scratch/` in a client worktree, run `scripts/setup-check.sh`: it ensures `.scratch/` and `.atl/` are in `$(git rev-parse --git-path info/exclude)` so they never show in `git status`. Agents may still append those two lines defensively. Do not put them in the client's `.gitignore`.

Before drafting a client delivery note, copy `docs/examples/nota-de-entrega.md` and run `scripts/check-delivery-note.sh` on the draft. Delete the author block (`BORRAR ANTES DE ENVIAR`) or the check fails. The client sees three sections: what changed, how to verify, and risks or pending confirmations. The note must not describe how the work was done, and must not name tools, models, the internal stack, local paths, or internal branch names. In a client repo, write the suggested text under `.scratch/` for Brayan and do not send it.

Merge: only Brayan merges, and only on his explicit order, in every repo. Never merge, enable auto-merge, or merge a PR yourself as a shortcut. Client repos: never `--force`, no push, MR or PR without Brayan's explicit order, stay inside the task worktree, and every step needs his approval except the local slice commit below.

Client slice commits (local only). Normal flow is the Slice loop in section 2: one ticket, one new session, checks, commit gate, one local commit, log in `.scratch/commits.md`, then stop. The next ticket starts in a new session. A recovery plan does not replace that new session. No extra ok: the slices were approved before code, each slice is one commit, and its message comes from the slice's issue. An approved out-of-scope bug is a separate `fix:` commit before that slice commit, not part of it. If the slice's scope changed from what was approved, do not commit: stop and tell Brayan. Recovery case: if, when the gate starts, uncommitted changes span more than one slice (or mix slices in one file), stop, show Brayan the commit plan (commits, files or hunks, messages) and wait for his ok before the first commit. That case is a failed gate, not the way to open the next ticket. Check detection (technology-agnostic), by priority: 1) the client KDB or `commit_checks` / `push_checks` in `clients.toml`; 2) what the repo already defines (package.json scripts, Makefile, `.sln`/`.csproj`, pyproject/tox, `go.mod`, `Cargo.toml`, `.pre-commit-config.yaml`; CI config as a reference for what the pipeline runs). Never invent checks: if none is found, do not commit, tell Brayan. Never install anything in a client repo: no hooks, no `core.hooksPath`, no new `.husky/`, `.githooks/` or pre-commit config.

Commit gate (light, every slice), in order; any failure means no commit: report the step and its real output, and stop.
1. Format and lint, only if the repo already uses them.
2. Fast compile or type check (incremental when the tool allows it).
3. Only the slice's tests (the ones TDD already runs). Classify them with `scripts/classify-test-failures.sh` as in Slice verification. Real failures block the slice. Env-known failures do not.
4. Existing pre-commit hooks run as they are; never use `--no-verify` or `CLIENT_PUSH_OK`. If one (including the opt-in `client-guard/pre-commit`) blocks, stop and tell Brayan.
5. Stage explicitly only the slice's files (`git add <paths>`, `git add -p` when a file mixes slices; never `git add -A` or `git add .`), then read `git diff --cached`: no secrets, no `.scratch/`, `.atl/` or config the KDB forbids, no stray debug output or new loose TODOs, no files outside the slice.
6. Identity and convention: if the client entry in `clients.toml` has `git_email`, `git config user.email` must equal it; without it, abort when the email looks personal (`@gmail.com`, `@users.noreply.github.com`, `@hotmail.com`, `@outlook.com`, `@icloud.com`). Never change git config to fix it. The message follows the project or KDB convention.

Pre-push gate (full), before asking Brayan for the push order: clean build; full test suite, plus coverage when a threshold exists; existing pre-push hooks; review every commit of the branch against its base (identity, message convention, the KDB's file limit per MR if it sets one). On a client project, also run the local security scan from `docs/security-scan.md`: when `gitleaks` is on PATH, from the worktree root scan only this branch against its base (`gitleaks git --log-opts="<base>..HEAD" --redact`, with `<base>` the merge base such as `origin/main` or the KDB default). Do not scan the full history for this gate; old commits may carry known debt that is not ours to fix here. When the binary is missing, warn and point at that playbook; do not install it into the client repo. SonarQube for IDE stays on the developer machine as an editor aid, not a gate command. Never install a hook, never commit scanner config, and never add a quality profile into the client repo for this step. The client pipeline remains the source of truth. A failure is fixed with a new commit; local amend or rebase only with Brayan's ok. Push still needs his explicit order.

After each gate, append to `.scratch/commits.md`: slice, commit hash, each check with its command, where it came from (KDB, clients.toml or repo file) and its real result.

Still only on Brayan's explicit order: push, MR or PR, merge, rebase, reset, amend, cherry-pick, `--force`, git config changes and hook installs.

Retro (decisions #29, #30): run `zretro` at the end of every Medium, Large or Critical task, on a Small task that had an error, and every time the user corrects you. It asks first what code or structure change would have made the mistake impossible (domain model, type, test, lint or check.sh guard), prefers that over a new rule, and removes any rule text the fix replaces. zretro reviews every pendiente in the retro log before proposing a new change. Client repos: a `.scratch/` proposal only. At close, write `.scratch/<slug>/calibracion.md` with tokens_estimados, holgura, tickets, tokens_reales, the size by risk, and the printed size. On a Large or Critical close, that file also gets a `## Modelos` table, one row per subagent, with the role, the preferred slug, the effective slug, and whether a quota fallback was used. The roles live in `docs/model-matrix.md`. A quota miss on the review role is recorded as stopped, not as a cheaper model. The shape is `docs/examples/calibracion-large.md`. Every size: end your final reply with this block, filled with facts from this session:

```
zstack check
- zstack invoked: yes
- size: <size>
- verifiable: <full|partial>
- not verified automatically: <none | item → how to check by hand>
- zninja launched: <yes | no (inline: <reason>)>
- poteto-mode loaded: <yes/no> (<zninja | inline>)
- reviewers: <none | zsensei | zsensei + security-auditor | inline self-check (small only) | independent (no Cursor)>
- summary: <short pseudocode>
- flow: <mermaid | none>
- evidence: <command → real result and limit | did not run: reason>
- tdd: <red and green commands with real results | not used>
```

Before reporting done, run `scripts/route-audit.sh` from this repo (Byevenes/agent-workflow). It counts most of the same facts (not verifiability) from Cursor transcripts and exits non-zero when a session edited inline without a reason, a Medium+ session edited without zsensei, or a Medium+ session edited without launching zninja (`medium+ inline`). A non-zero exit is a retro input, not something to explain away.

### Unslop before handoff

After the draft and before handoff, unslop `to-analysis`, `to-questionnaire`, `to-techspec`, the client delivery note, and a ticket-comment draft. Cut filler and stock phrases. Keep facts, uncertainties, requirements, technical terms, and every required heading. Run `scripts/check-draft-sections.sh <kind> <draft>` with kind `analysis`, `questionnaire`, `techspec`, `delivery-note`, or `ticket-comment`. A missing heading fails the check. Example: `docs/examples/unslop-before-after.md`. A ticket-comment draft is not published.
