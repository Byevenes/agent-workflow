# Workflow

One order for a feature and for a fix.

1. A task shows up in Jira or GitLab, or as a note in this repo's `.scratch/` tracker.
2. Engineer Lead, on the outer loop, splits it. It does not implement.
3. Locally, `grill-with-docs` settles the decision when it fits in one session. `wayfinder` is only for work that does not.
4. `to-spec` writes the spec into the issue tracker.
5. Herdr, inside cmux, holds two panes: Cursor CLI with pstack, and OpenCode with Oh My OpenAgent.
6. `poteto-mode` implements on the pane that has the repo.
7. `retro` runs once, after the check passes.

Dr Eggbot is outside this chain. Use it only to design or audit a bot.

`skills/route-work` is the local entry that calls those skills in this order. `agents/coordinator.md` delegates. `agents/implementer.md` builds.
