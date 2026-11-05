---
name: zretro
description: "zStack wrapper for Matt Pocock's retro. Use at the end of every Medium, Large or Critical task, on a Small task that had an error, and every time the user corrects the agent."
---

# zretro

Read `~/.agents/skills/retro/SKILL.md` and follow it, with these overrides:

- For each mistake, ask first: what change to the code or its structure would have made this mistake impossible, or caught it at once? The codebase is the prompt, so improve it before adding rules.
- Pick the fix in this order: a domain model or module boundary (one owner, a deep module with a small interface, a clear name in `GLOSSARY.md`), then a type that makes the bad state unrepresentable, then a behavior test, then a lint, hook or `scripts/check.sh` guard whose error names the fix. Prove it fails on the real mistake from this session.
- Rule or skill text is the last resort. Write `no structural fix because <reason>` before you add one.
- When a barrier replaces a sentence in a skill, rule or AGENTS.md, delete the sentence in the same change.
- Start from `scripts/route-audit.sh` (agent-workflow): every inline edit without a reason and every Medium+ edit without zsensei is a mistake to retro.
- Review every pendiente in the retro log before proposing a new change.
- Confirm the row when the mistake did not return. The state becomes confirmado.
- Revert the row when the change did not help. The state becomes revertido, and the script restores the pre-change bytes when that is safe.
- In a personal repo, run `scripts/retro-log.sh begin` before the edit and `scripts/retro-log.sh seal` after it.
- A client proposal is not a log row until the change is applied.
- When the script is absent, write the same TSV by hand.
- At close, write `.scratch/<slug>/calibracion.md` with the fields zstack section 5 names.
- On a Large or Critical close, add a `## Modelos` table to that file, one row per subagent, using the shape in `docs/examples/calibracion-large.md`. Read `docs/model-matrix.md` for the preferred slug. Keep the review role on its Opus slug. A quota miss there is stopped, not a cheaper model.
- Present the candidates ranked, as Matt's retro says. The user picks.
- Personal repos: implement the picked barriers in the same PR or a follow-up PR.
- Client repos: write the proposal to `.scratch/retro-<date>.md` only. Brayan approves before anything changes.

If Matt's file does not exist, use the overrides above with the seven retro categories: navigation, automated checks, coding standards, steering files, tool economy, no-ops, information access.
