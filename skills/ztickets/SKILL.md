---
name: ztickets
description: "zStack wrapper for Matt Pocock's to-tickets. Use on Large tasks to split the spec into the ticket count from Classify, before the approval gate."
---

# ztickets

Read `~/.agents/skills/to-tickets/SKILL.md` and follow it exactly, with these overrides:

- Write every output to `.scratch/` in the current worktree.
- Never publish or create issues in Jira, GitLab, GitHub or any tracker without the user's explicit ok. In client repos, never.
- Tickets stay as local files in `.scratch/` unless the user approves publishing them.
- The slice count is the ticket count Classify computed in section 1 of `skills/zstack/SKILL.md`. Each slice fits one session of that budget.

If that file does not exist, stop and tell the user: "run `/to-tickets` manually (I can't invoke it)".
