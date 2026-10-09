# MCP

Tokens and database URLs stay in the environment. This file names the variable. It does not contain a value.

## Already configured

These were already present. This cut does not remove them.

- Figma
- Figma Desktop
- Atlassian, used for Jira
- codegraph
- context7
- engram
- stitch
- agent-browser

OpenCode has the same set except Figma cloud.

## Added in this cut

| Server | How it starts | Variable |
| --- | --- | --- |
| GitHub | Remote `https://api.githubcopilot.com/mcp/` | `GITHUB_PERSONAL_ACCESS_TOKEN` |
| GitLab | `scripts/mcp-gitlab.sh` runs `@modelcontextprotocol/server-gitlab` | `GITLAB_PERSONAL_ACCESS_TOKEN` |
| Postgres | `scripts/mcp-postgres.sh` runs `@modelcontextprotocol/server-postgres` | `POSTGRES_URL` |
| Playwright | `npx -y @playwright/mcp@latest` | none |

`agent-browser` stays. Playwright is the extra check for screens. The value review compares them. Neither is removed here.

The coordinator uses GitHub, GitLab, and Atlassian. The implementer uses Playwright, and Postgres only when the spec touches the database.

If a variable is unset, that server does not start. The script says which variable is missing and does not print the value.
