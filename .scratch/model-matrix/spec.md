# model-matrix

Status: ready-for-agent

## Problem Statement

When a model's quota runs out, a role can be dropped or moved onto the wrong model. A Large retro cannot say which slug each subagent actually used. The owner wants the review role to stay on Claude Opus.

## Solution

A durable matrix in this repo names each zStack role, its preferred slug, and its quota fallback. The review role is Claude Opus fixed and has no fallback that downgrades judgment. A Large or Critical close adds the effective slug of each subagent to the calibration file that already exists.

## User Stories

1. As zIGL, I want one matrix of role, preferred model, and quota fallback, so that a quota miss has a named next step.
2. As zIGL, I want implement and spec to prefer `grok-4.7-medium` and fall back to `inherit-parent`, so that the fallback is a slug the owner rule already allows.
3. As a reviewer, I want the review role documented as Claude Opus fixed (`claude-opus-5-5-medium`), so that judgment is not downgraded.
4. As a reviewer, I want that role to have no quota fallback, so that exhaustion stops and asks the owner.
5. As zretro, I want a Large or Critical close to record each subagent's effective model in the calibration file, so that cost and quality can be calibrated.
6. As zretro, I want that record to be a `## Modelos` table, so that the shape matches one example.
7. As a reviewer, I want `scripts/check.sh` to fail when the Opus pin, the empty review fallback, or the close pointer is missing, so that the matrix cannot vanish.
8. As a maintainer, I want the user rule file pstack-models.mdc left untouched and outside this repo, so that the live pstack override stays the owner's file.
9. As a maintainer, I want OpenCode's inherit rule and the client `opencode/*` ban left as they are, so that this matrix does not retarget client work.
10. As a maintainer, I want the example toml to be documentation, so that no client repo loads it.

## Implementation Decisions

- The source agents read is `docs/model-matrix.md`. Skills only point at it.
- The example config is `docs/examples/model-matrix.toml`. No client repo loads it.
- Close state stays in the calibration file from zstack section 5. Large and Critical add `## Modelos`. The example shape is `docs/examples/calibracion-large.md`.
- The review agent is zsensei. The preferred slug is `claude-opus-5-5-medium`. The fallback list is empty.
- The implement agent is zninja. The spec agents are zgrill, zspec, and ztickets. The preferred slug is `grok-4.7-medium`. The quota fallback is `inherit-parent`.
- `quota_fallback` in the close table is `no`, `yes`, or `stopped`. `stopped` is only for the review role when Opus quota is exhausted and the owner has not chosen another slug.
- The matrix does not copy the whole pstack panel. It does not edit pstack-models.mdc.
- `GLOSSARY.md` gains Preferred model, Quota fallback, and Effective model.
- `docs/scripts.md` mentions the new `scripts/check.sh` greps on the existing check.sh bullet.
- OpenCode stays as written in `agents/opencode/zstack.md`.

## Testing Decisions

- The seam is `scripts/check.sh`. A good test fails when a required sentence is absent.
- Prior art is the `grep -qF` checks next to the calibration path.
- Progress is `sh scripts/check.sh` exiting 0.

## Out of Scope

- Editing pstack-models.mdc or any file under the user Cursor or config directories.
- Changing zsensei's model frontmatter or the OpenCode inherit sentence.
- A runtime loader, a client-repo change, a new hook, or a TLA+ edit.
- A second fallback slug beyond `inherit-parent`.

## Further Notes

Where the state lives. `docs/model-matrix.md` holds the contract. `docs/examples/model-matrix.toml` holds the example. The calibration file holds the close log. `docs/examples/calibracion-large.md` holds the Large shape.

How progress and success are measured. `sh scripts/check.sh` is green, including the new greps.
