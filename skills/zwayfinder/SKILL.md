---
name: zwayfinder
description: "zStack wrapper for Matt Pocock's wayfinder. Use when a plan does not fit one session and the way to the destination is still foggy."
---

# zwayfinder

Read `~/.agents/skills/wayfinder/SKILL.md` and follow it exactly, with these overrides:

- Write every output (the map and its tickets) to `.scratch/` in the current worktree. Do not create tracker issues by default.
- Never publish or create issues in Jira, GitLab, GitHub or any tracker without the user's explicit ok. In client repos, never.
- Do not use this to start a spec that is already ready. If the way to the destination is already clear, or a spec already exists, stop and say so (Matt already says: if charting surfaces no fog, you don't need a map).

If that file does not exist, stop and tell the user: "run `/wayfinder` manually (I can't invoke it)".
