---
name: zspec
description: "zStack wrapper for Matt Pocock's to-spec. Use after zgrill on Medium, Large or Critical tasks to write the spec before code."
---

# zspec

Read `~/.agents/skills/to-spec/SKILL.md` and follow it exactly, with these overrides:

- Write every output to `.scratch/` in the current worktree.
- Never publish or create issues in Jira, GitLab, GitHub or any tracker without the user's explicit ok. In client repos, never.
- If the spec does not say yet, ask "where does the state live?" and "how do we measure progress and success?".
- A spec cites a file from the repo root, for example `src/Foo/Bar.cs`. On a TechSpec, run `scripts/check-techspec-paths.sh <markdown> <repo-root>`. The command fails when a cited path does not exist from that root or is an absolute machine path.

If that file does not exist, stop and tell the user: "run `/to-spec` manually (I can't invoke it)".
