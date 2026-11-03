---
name: zretro
description: "zStack wrapper for Matt Pocock's retro. Use at the end of every Medium, Large or Critical task, on a Small task that had an error, and every time the user corrects the agent."
---

# zretro

Read `~/.agents/skills/retro/SKILL.md` and follow it, with these overrides:

- Each candidate ends in exactly one barrier: a lint rule, a hook check, a test, a type, or a `scripts/check.sh` guard. When none fits, write `no barrier possible because <reason>` and keep it as a judgment rule for the reviewer.
- Pick the barrier with pstack's `correct` order: architecture, then types, then a lint whose error names the fix, then a test, then docs last. Prove the barrier fails on the real mistake from this session.
- When a barrier replaces a sentence in a skill, rule or AGENTS.md, delete the sentence in the same change.
- Present the candidates ranked, as Matt's retro says. The user picks.
- Personal repos: implement the picked barriers in the same PR or a follow-up PR.
- Client repos: write the proposal to `.scratch/retro-<date>.md` only. Brayan approves before anything changes.

If Matt's file does not exist, use the overrides above with the seven retro categories: navigation, automated checks, coding standards, steering files, tool economy, no-ops, information access.
