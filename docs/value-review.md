# Value review

Recorded while publishing this repo. Nothing in this list was deleted.

## tdd name collision

`~/.agents/skills/tdd` is now Matt Pocock's skill. The installer replaced the folder that was already there. No copy of the previous skill was found under OpenCode. Cursor's `~/.cursor/skills` did not have a `tdd` folder, so the previous text is gone. This repo does not restore it. The Matt skill is the one `docs/testing.md` points at.

`code-review` arrived with Matt's set. The longer review skill already installed is `code-review-and-quality`. Both stay.

## Overlap

Matt's `to-spec` and `to-tickets` overlap the SDD skills already in `~/.cursor/skills` (`sdd-spec`, `sdd-tasks`, and the rest of that set). The files stay. `skills/route-work` does not call the SDD chain. It calls Matt's skills before code, and only the ones the size needs.

## What this flow does not load

Nothing here is deleted. Other repos may still name these files. `route-work` does not call them.

- Matt's `code-review`. It repeats the spec axis and opens two subagents. `code-reviewer` loads `code-review-and-quality` once, on medium and large.
- `interrogate`, unless the user asks for a contested design.
- `review-risk`, `review-readability`, `review-reliability`, `review-resilience`, `review-refuter`, and `judgment-day`.
- `sdd-explore` through `sdd-verify`, `tech-lead`, and `senior-code-engineer`. Definition is `grill-with-docs` and `to-spec`. `prd-td-coherence` runs only when a PRD and a design already exist.
- `test-engineer`, unless the user asks for a test strategy. The change's tests come from pstack's `tdd` inside `poteto-mode`.
- `security-auditor` on anything that is not critical. `security-and-hardening` runs during implementation only when the change touches input, a session, personal data, or an integration.

`code-review` and `code-review-and-quality` both stay installed. Only the second is on this path, and only through `code-reviewer`.

## Browsers

`agent-browser` stays configured in Cursor and OpenCode. Playwright is added beside it for screen checks. Neither replaces the other in this cut.

## OpenCode agents

Sisyphus, Hephaestus, Prometheus, Atlas, and Gentleman stay. This repo only adds `coordinator` and `implementer` when those names are free.

## Models

pstack's default slugs `grok-4.7-xhigh-fast` and `claude-opus-5-5-xhigh` were not in the model list detected for this session. The user rule uses `grok-4.7-medium` and `claude-opus-5-5-medium`, which were detected. `inherit-parent` and `auto` stay valid.
