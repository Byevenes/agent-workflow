---
name: ztickets
description: "zStack wrapper for Matt Pocock's to-tickets. Use on Large tasks to split the spec into slices before the approval gate."
---

# ztickets

Read `~/.agents/skills/to-tickets/SKILL.md` and follow it exactly, with these overrides:

- Write every output to `.scratch/` in the current worktree.
- Never publish or create issues in Jira, GitLab, GitHub or any tracker without the user's explicit ok. In client repos, never.
- Tickets stay as local files in `.scratch/` unless the user approves publishing them.

If that file does not exist, stop and tell the user: "run `/to-tickets` manually (I can't invoke it)".
