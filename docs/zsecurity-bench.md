# zsecurity mini-bench

Gate before `agents/zsecurity.md` replaces `security-auditor` on the Critical path in `skills/zstack/SKILL.md`. Until this bench passes, zstack keeps `security-auditor` there, and zsecurity is registered but only launched by hand or when zsensei recommends a dedicated security review.

Status: not run. No model run is recorded in this repo.

## Fixtures

Three seeded bugs, one per diff, each a new file so it applies to any empty scratch repo:

| Diff | Seeded bug | Class | Expected finding |
| --- | --- | --- | --- |
| `docs/examples/zsecurity-bench/idor.diff` | `src/invoices.js` reads `req.params.id` and returns the invoice without comparing its owner to `req.session.userId` | authz / IDOR | any signed-in user reads another user's invoice |
| `docs/examples/zsecurity-bench/ssrf-webhook.diff` | `src/webhooks.js` fetches a user-supplied URL; the only check is `startsWith('http')`, and the response body is echoed back | SSRF | `http://169.254.169.254/latest/meta-data/` or a private host is reachable and its body is returned |
| `docs/examples/zsecurity-bench/derived-path-delete.diff` | `scripts/clean-worktree.sh` runs `rm -rf "$WT_ROOT/$name"` with `name` from argv | destructive operation on a derived path | `name=..` or an empty `WT_ROOT` deletes outside the worktree root |

`scripts/check.sh` only checks that the three diffs exist and parse. It does not run a model.

## How to run

1. In a personal scratch repo (never a client repo), commit an empty base, then apply one diff per branch: `git apply docs/examples/zsecurity-bench/<name>.diff`.
2. For each branch, run the upstream `security-auditor` (addy `0.6.17`) and `zsecurity` on the same model, with the same BASE_SHA and HEAD_SHA, each in a fresh context.
3. Count per reviewer: real findings (matches the table), noise (anything else reported as a finding), and known misses.

## Pass rule

zsecurity passes when it reports all three seeded bugs with evidence, and reports no more noise than `security-auditor`. Then wire it in section 4 of `skills/zstack/SKILL.md` (Critical: `zsensei`, then `zsecurity`), in `docs/workflow.md`, and in the review package. If it misses a seeded bug, keep `security-auditor` and turn the miss into a rule in `agents/zsecurity.md`.
