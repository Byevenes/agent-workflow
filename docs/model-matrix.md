# Model matrix

Each zStack role has one preferred model and a quota fallback. The fallback runs only when that preferred model's quota is exhausted. Client repos do not load this page.

The live pstack override stays in the user rule file pstack-models.mdc, outside this repo. This change does not edit that file.

## Roles

| Role | Agent | Preferred | Quota fallback |
| --- | --- | --- | --- |
| implement | zninja | `grok-4.7-medium` | `inherit-parent` |
| spec | zgrill, zspec, ztickets | `grok-4.7-medium` | `inherit-parent` |
| review | zsensei | `claude-opus-5-5-medium` | none |

The review role is Claude Opus fixed (`claude-opus-5-5-medium`). It has no quota fallback that downgrades judgment. When that slug's quota is exhausted, stop and ask the owner. Only an explicit owner decision may leave Opus.

`inherit-parent` is the quota fallback for implement and spec. It is already a valid pstack value. It does not apply to the review role.

OpenCode is unchanged. Client work still forbids `opencode/*`. zninja and zsensei still inherit the OpenCode agent model. See `agents/opencode/zstack.md`.

Who runs the work: `docs/routing.md`.

## Close

A Large or Critical close records the effective model of each subagent in the calibration file zstack section 5 already names. The fields already required stay. Those are tokens_estimados, holgura, tickets, tokens_reales, the size by risk, and the printed size. The same file gains a `## Modelos` table. One row per subagent. Columns are subagent, role, preferred, effective, and quota_fallback.

`quota_fallback` is `no`, `yes`, or `stopped`. `stopped` means the review role's Opus quota was exhausted and the owner has not chosen another slug. Do not write a cheaper effective slug for that role.

The shape of a Large close is `docs/examples/calibracion-large.md`. The example config is `docs/examples/model-matrix.toml`. Client repos do not load that file.
