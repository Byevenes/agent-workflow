---
name: zgrill
description: "zStack wrapper for Matt Pocock's grill-me / grill-with-docs. Use when a plan or design has open decisions before code (zStack Small with an open decision, Medium, Large, Critical)."
---

# zgrill

Small: read `~/.agents/skills/grill-me/SKILL.md`. Medium, Large, Critical: read `~/.agents/skills/grill-with-docs/SKILL.md`. Follow it exactly, with these overrides:

- Write every output to `.scratch/` in the current worktree.
- Never publish or create issues in Jira, GitLab, GitHub or any tracker without the user's explicit ok. In client repos, never.
- If not already covered, ask "where does the state live?" for every piece of state the change touches, and "how do we measure progress and success?".

If that file does not exist, stop and tell the user: "run `/grill-me` (or `/grill-with-docs`) manually (I can't invoke it)".
