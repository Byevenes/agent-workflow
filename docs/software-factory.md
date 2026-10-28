# Software factory

How one task moves through this setup, from intake to retro. `skills/route-work/SKILL.md` is the source; this page is the map.

```mermaid
flowchart TD
  task[Task in a new session] --> rule[rules/route-work.mdc always on]
  rule --> rw[route-work classifies: route-work: size, verifiability — reason]
  rw -->|Small| sPlan[grill-me only if a decision is open]
  rw -->|Medium| mPlan[grill-with-docs → to-spec in .scratch/ · optional ADR / statechart]
  rw -->|Large| lPlan[Medium + to-tickets · wayfinder if multi-session]
  rw -->|Critical| cPlan[Large + security-and-hardening · formal-verification optional]
  lPlan --> gate{{User approval before code}}
  cPlan --> gate
  sPlan --> impl
  mPlan --> impl
  gate --> impl[implementer subagent via Task]
  impl --> pm[loads poteto-mode SKILL.md → reports poteto-mode: loaded]
  pm --> tdd[pstack tdd · project checks]
  tdd -->|Small| done[Parent reads diff and checks]
  tdd -->|Medium| cr[code-reviewer: spec still matches diff]
  tdd -->|Large| br[blast-radius] --> cr
  tdd -->|Critical| cr2[code-reviewer] --> sa[security-auditor]
  cr --> retro[retro]
  sa --> retro
  done --> check[route-work check block]
  retro --> check
  check --> audit[scripts/route-audit.sh counts it from transcripts]
```

## Where it is wired

| Harness | Always-on entry | Installed by |
| --- | --- | --- |
| Cursor GUI | `~/.cursor/rules/route-work.mdc` (`alwaysApply: true`) | `scripts/link.sh` (symlink) |
| Cursor CLI (`agent`) | same user rule, plus the repo's `AGENTS.md` | `scripts/link.sh` |
| OpenCode | `~/.config/opencode/route-work.md` listed in `instructions` of `opencode.json` | `scripts/link.sh` links the file; add the `instructions` entry once by hand |

## Fixed retro check

Every retro answers, with numbers from `scripts/route-audit.sh <project> <days>`:

- ¿Se invocó route-work?
- ¿implementer lanzó poteto-mode? (`poteto-mode: loaded` in its report)
