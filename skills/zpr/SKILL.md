---
name: zpr
description: "zStack wrapper for Matt Pocock's pr skill. Use whenever you write a PR or MR body."
---

# zpr

Read `~/.agents/skills/pr/SKILL.md` and follow it (Summary visual, Evidence, Merge Danger), with these additions in this order:

1. `## Why` first: what changes and why, in 2 or 3 sentences, in the user's goal words.
2. `## Summary`: Matt's smallest visual. Use Mermaid when a flow or the architecture changes.
3. `## Files`: one table, rows grouped by intent (for example hooks, docs, scripts), one line per file.
4. `## Evidence`: only checks that actually ran, each with its real output or result. Say what was not verified.
5. `## Merge Danger`: door, blast radius, and how to roll back.
6. `## Left out`: follow-ups and known gaps.

Write in the repo's language. Never paste secrets, tokens or client data.

- Personal repos: use this for every PR. CI fails a body without `## Why`, `## Summary` and `## Merge Danger`.
- Client repos (`~/Sites/tinet/Clients/**`, GitLab client MRs): write a suggested body to `.scratch/pr-body.md` for Brayan. Never post it or open the PR or MR yourself.

If Matt's file does not exist, use the six sections above on their own.
