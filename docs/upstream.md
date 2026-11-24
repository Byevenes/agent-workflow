# Upstream pins

Measured when this repo was first published.

| Piece | Pin |
| --- | --- |
| Matt Pocock skills | `mattpocock/skills` @ `49dd158d1076134a641b33efb035946536778336` |
| pstack | Cursor plugin `0.15.46` (installed plugin cache, bumped from `0.15.15`). Not forked. |
| cursor-team-kit | `1.2.0`, copied into the local Cursor plugins folder from `cursor/plugins`. |
| addy `security-and-hardening` | `addyosmani/agent-skills` tag `0.6.17` @ `8c99fa36d90068c82d547f7c12a9d67a3e95f4ee`. Installed by `scripts/install-security-hardening.sh`, with `references/security-checklist.md` vendored into the skill folder. |
| addy `security-auditor` | Not pinned. Replaced by `agents/zsecurity.md` once `docs/zsecurity-bench.md` passes; until then the installed copy stays on the Critical path. |

Install Matt again with:

```bash
npx skills@latest add mattpocock/skills -g -a cursor -a opencode -y --skill '*' --copy
```

Install `security-and-hardening` again with:

```bash
scripts/install-security-hardening.sh
```

It clones the tag, refuses a tag that does not resolve to the pinned sha, copies the skill to `~/.agents/skills/security-and-hardening`, and points `~/.cursor/skills` and `~/.config/opencode/skills` at that one copy. A loose copy is moved to `~/.cache/agent-workflow/replaced-skills`, never deleted. A second run at the same pin changes nothing.

Do not vendor these trees into this repo. This file is the pin.
