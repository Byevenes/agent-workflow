# Inventory

Names only. No client urls and no tokens.

## Cursor

User skills live in `~/.cursor/skills`. User agents live in `~/.cursor/agents`. The pstack plugin is installed from the Cursor marketplace, version `0.15.15`. `cursor-team-kit` `1.2.0` is in the local plugins folder.

MCP already configured: Figma, Figma Desktop, Atlassian, codegraph, context7, engram, stitch, agent-browser.

## OpenCode

Oh My OpenAgent is configured. Agents present include Sisyphus, Hephaestus, Prometheus, Atlas, and Gentleman, plus the shared engineering agents. This repo adds `coordinator` and `implementer` by symlink. It does not remove the others.

MCP already configured: Atlassian, codegraph, context7, engram, Figma Desktop, stitch, agent-browser. Figma cloud is not in this OpenCode config.

## Herdr and the terminal

Herdr `0.9.3` is on the PATH. Integrations for OpenCode and Cursor CLI are installed. cmux stays installed. Herdr runs inside it.

## Shared skills folder

`~/.agents/skills` is read by more than one tool. Matt Pocock's skills were installed there and mirrored into Cursor and OpenCode when the name was free. See `docs/value-review.md` for the `tdd` name collision.
