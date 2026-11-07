---
name: verify-zwt
description: "Verify the zwt subsystem. Names the command to run and the result that counts as green."
---

# verify-zwt

Scope is the zwt subsystem, not the general verification map.

Command: `bun run typecheck && bun run test && bun run build`

Add `bun run lint` when zwt #40 lands.

Green: those commands exit 0.

Add another subsystem as `skills/verify-<name>/SKILL.md` with its own command and green result. Leave the general verification map unchanged.
