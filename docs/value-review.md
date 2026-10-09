# Value review

Recorded while publishing this repo. Nothing in this list was deleted.

## tdd name collision

`~/.agents/skills/tdd` is now Matt Pocock's skill. The installer replaced the folder that was already there. No copy of the previous skill was found under OpenCode. Cursor's `~/.cursor/skills` did not have a `tdd` folder, so the previous text is gone. This repo does not restore it. The Matt skill is the one `docs/testing.md` points at.

`code-review` arrived with Matt's set. The longer review skill already installed is `code-review-and-quality`. Both stay.

## Overlap

Matt's `to-spec` and `to-tickets` overlap the SDD skills already in `~/.cursor/skills` (`sdd-spec`, `sdd-tasks`, and the rest of that set). This cut keeps both. `skills/route-work` calls the Matt skills for the definition pass and pstack for the implementation pass.

## Browsers

`agent-browser` stays configured in Cursor and OpenCode. Playwright is added beside it for screen checks. Neither replaces the other in this cut.

## OpenCode agents

Sisyphus, Hephaestus, Prometheus, Atlas, and Gentleman stay. This repo only adds `coordinator` and `implementer` when those names are free.

## Models

pstack's default slugs `grok-4.7-xhigh-fast` and `claude-opus-5-5-xhigh` were not in the model list detected for this session. The user rule uses `grok-4.7-medium` and `claude-opus-5-5-medium`, which were detected. `inherit-parent` and `auto` stay valid.
