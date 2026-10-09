---
name: route-work
description: "Route a change through grill-with-docs, to-spec, poteto-mode, and retro. Use when starting work in this workflow stack."
disable-model-invocation: true
---

# Route work

Do not implement in this skill. Call the other skills in order.

1. Call the Skill tool with `grill-with-docs` when the change is still a decision. Skip it only when a spec already exists for this change.
2. Call the Skill tool with `to-spec`. Publish the spec to this repo's issue tracker (`.scratch/`).
3. Call the Skill tool with `poteto-mode` to implement that spec. The implementer agent does the code. This skill does not.
4. Call the Skill tool with `retro` once, after the implementation check passes.

If the work does not fit in one session, call the Skill tool with `wayfinder` instead of holding it all in `grill-with-docs`.

Do not write domain docs, skills, or rules into any repo other than this one unless the user says to write them there.
