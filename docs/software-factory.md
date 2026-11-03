# Software factory

How one task moves through this setup, from intake to retro. `skills/zstack/SKILL.md` is the source; this page is the map.

```mermaid
flowchart TD
  task[Task in a new session] --> rule[rules/zstack.mdc always on]
  rule --> rw[zstack classifies: zstack: size, verifiability — reason]
  rw -->|Small| sPlan[zgrill only if a decision is open]
  rw -->|Medium| mPlan[zgrill → zspec in .scratch/ · optional ADR / statechart]
  rw -->|Large| lPlan[Medium + ztickets · wayfinder if multi-session]
  rw -->|Critical| cPlan[Large + security-and-hardening · formal-verification optional]
  lPlan --> gate{{User approval before code}}
  cPlan --> gate
  sPlan --> impl
  mPlan --> impl
  gate --> impl[zninja via Task or inline]
  impl --> pm[zninja or inline session loads poteto-mode SKILL.md → reports poteto-mode: loaded]
  pm --> tdd[pstack tdd · project checks]
  tdd -->|Small| done[Parent or inline session reads diff and checks]
  tdd -->|Medium| cr[zsensei: spec still matches diff]
  tdd -->|Large| br[blast-radius] --> cr
  tdd -->|Critical| cr2[zsensei] --> sa[security-auditor]
  cr --> retro[retro]
  sa --> retro
  done --> check[zstack check block]
  retro --> check
  check --> audit[scripts/route-audit.sh counts it from transcripts]
```

The inline trigger is in section 3 of `skills/zstack/SKILL.md`. That `impl` step then runs in the same session. The check block records `zninja launched: no (inline: <reason>)`. `scripts/route-audit.sh` counts delegated launches only; inline runs show as not launched.

## Where it is wired

| Harness | Always-on entry | Installed by |
| --- | --- | --- |
| Cursor GUI | `~/.cursor/rules/zstack.mdc` (`alwaysApply: true`) | `scripts/link.sh` (symlink) |
| Cursor CLI (`agent`) | same user rule, plus the repo's `AGENTS.md` | `scripts/link.sh` |
| OpenCode | `~/.config/opencode/zstack.md` listed in `instructions` of `opencode.json` | `scripts/link.sh` links the file; add the `instructions` entry once by hand |

## Fixed retro check

Every retro answers, with numbers from `scripts/route-audit.sh <project> <days>`:

- ¿Se invocó zstack?
- ¿zninja lanzó poteto-mode? (`poteto-mode: loaded` in its report)
