---
name: zwrite
description: "zStack wrapper for the external writing-for-agents skill. Use when creating or editing AGENTS.md or a rule the agent loads."
---

# zwrite

Read `~/.agents/skills/writing-for-agents/SKILL.md` and follow it, with these overrides:

- Write `AGENTS.md` and files under `rules/`. Point at `docs/agents/` instead of copying those pages into `AGENTS.md`.
- Do not edit `skills/zretro/SKILL.md`. A retro stays on zretro.
- Do not copy the external skill into this repo.
- Keep `AGENTS.md` a short list of navigation pointers. A rule states the behavior to follow.
- In a client repo, edit those files only when the user asks, and do not publish the edit.

If that file does not exist, stop and tell the user: "run `/writing-for-agents` manually (I can't invoke it)".
