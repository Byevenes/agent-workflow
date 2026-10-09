# Spec: publish the workflow stack

Status: ready-for-agent

## Outcome

A public repo named `agent-workflow` that another machine can clone. `scripts/link.sh` wires skills and agents. `scripts/setup-check.sh` reports what is present without printing secrets.

## In

- README, glossary, agents that delegate, one router skill
- Docs for upstream pins, inventory, MCP, Grok roster, workflow, testing, value review, and this retro
- Local markdown issue tracker
- User-level Matt skills, pstack left as already installed, cursor-team-kit present, Herdr integrations, four added MCP servers

## Out

- Client repository commits
- Deleting existing OpenCode agents
- New Grok bots
- Secret values in git
