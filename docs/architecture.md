# Architecture

How this repo is wired and how a task moves through zStack. `skills/zstack/SKILL.md` is the source of truth; this page only draws it.

## 1. Repo to user folders

`scripts/link.sh` symlinks the repo into the folders Cursor and OpenCode read. It is idempotent, removes old links that point into this repo (route-work rule, implementer, code-reviewer, coordinator), sets `core.hooksPath` to `.githooks`, and mirrors Matt's skills from `~/.agents/skills` and pstack skills when the name is free.

```mermaid
flowchart LR
  subgraph repo[agent-workflow repo]
    sk[skills/zstack, route-work alias]
    wr[skills/zgrill, zspec, ztickets, zpr, zretro]
    ru[rules/zstack.mdc]
    ag[agents/zigl, zninja, zsensei]
    oc[agents/opencode/zstack.md]
  end
  link[scripts/link.sh]
  repo --> link
  link --> cs[~/.cursor/skills]
  link --> cr[~/.cursor/rules/zstack.mdc]
  link --> ca[~/.cursor/agents]
  link --> os[~/.config/opencode/skills]
  link --> om[~/.config/opencode/zstack.md]
  link --> oa[~/.config/opencode/agents]
  matt[~/.agents/skills: Matt Pocock] --> link
  pstack[pstack plugin cache] --> link
```

## 2. Task flow

`rules/zstack.mdc` is always on, so each session starts in zStack as zIGL. zIGL classifies the size and loads only that path. Matt's planning skills keep `disable-model-invocation`, so zStack calls them through wrappers that read Matt's file and add our rules. zNinja writes the code with poteto-mode; zIGL works inline only on the trigger in section 3 of the skill, and records the reason. zSensei reviews Medium and up. zretro ends in a barrier, and zpr writes the PR body.

```mermaid
flowchart TD
  task[task] --> zigl[zIGL classifies]
  zigl -->|Small| s[zgrill only if a decision is open]
  zigl -->|Medium| m[zgrill, then zspec in .scratch/]
  zigl -->|Large| l[zgrill or wayfinder, zspec, ztickets, human gate]
  zigl -->|Critical| c[Large path plus security-and-hardening]
  s & m & l & c --> impl{Task tool lists zninja?}
  impl -->|yes| zn[zNinja subagent, poteto-mode]
  impl -->|no, reason stated| inl[inline: poteto-mode in this session]
  zn & inl --> rev{Medium or up?}
  rev -->|yes| zs[zSensei review; Critical adds security-auditor]
  rev -->|no| ck
  zs --> retro[zretro]
  retro --> bar[barrier: hook, lint, test, type, check.sh guard]
  bar --> ck[zstack check block]
  ck --> pr[zpr PR body]
  pr -->|personal repo| gh[PR on GitHub]
  pr -->|client repo| draft[.scratch/pr-body.md for Brayan]
```

## 3. Guardrails

Each guard runs at a different moment. The pre-commit hook and CI run the same `scripts/check.sh`. GitHub protects `main`: a PR with a green `check` is the only way in. `setup-check.sh` and `route-audit.sh` are manual reports. `route-audit.sh` exits 1 when a zstack session has no parseable size (`size undetected`). The canonical line is `zstack: <Small|Medium|Large|Critical>, <full|partial> verifiable — <reason>`; older variants (`Clasificación **Small**`, `size: Small`) still count, reported as `legacy format`.

```mermaid
flowchart LR
  edit[edit] --> pc[pre-commit: block main, block staged secrets]
  pc --> chk[scripts/check.sh]
  chk --> c1[shellcheck required]
  chk --> c2[inline trigger in one file]
  chk --> c3[old names, --force rule, no-comments]
  chk --> c4[link.sh smoke in temp HOME]
  chk --> c5[route-work alias fails after 2026-12-01]
  chk --> push[push branch]
  push --> ci[CI check: check.sh and zpr headings in PR body]
  ci --> prot[main protection: PR plus green check, no force push]
  setup[setup-check.sh: links, wrappers, optional env] -.-> edit
  audit[route-audit.sh: zninja vs inline counts] -.-> retro[zretro]
```

## Verified statechart

`docs/statechart/` holds a TLA+ model of this flow, checked with TLC via pstack's `/statechart` (decision #23). With option B every rule holds when the agent obeys the skill text; with no barriers (today) each rule breaks, so all six hold by text, not by a blocking hook. CI job `tla` reruns TLC when the skill or the model changes. See [docs/statechart/README.md](statechart/README.md) and [chart.mmd](statechart/chart.mmd).

## Hard barriers (opt-in)

| Barrier | What blocks | Install (Brayan) | Bypass |
|---|---|---|---|
| `hooks/client-guard/pre-push` | `git push` from any repo under `~/Sites/tinet/Clients/` or to a remote matching `CLIENT_GUARD_HOSTS` (default `bitbucket.org gitlab.`) | In each client repo: `cp ~/Sites/personal/agent-workflow/hooks/client-guard/pre-push "$(git rev-parse --git-path hooks)/pre-push"` (repos with husky or a local `core.hooksPath`: add it there instead) | `CLIENT_PUSH_OK=brayan git push`, or `--no-verify` |
| Agent identity for merges | Nothing yet: the agent's GitHub token is Brayan's admin account | Give the agent its own GitHub identity (machine user or GitHub App) with write access; add a ruleset on `main` with **Restrict updates** and bypass list = repository admin (Brayan) | Brayan's account |

`scripts/setup-check.sh` reports both (`client-guard`, `merge-guard`). Agents never install the hook in client repos nor touch global git config.
