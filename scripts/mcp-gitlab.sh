#!/bin/sh
# Start the GitLab MCP server. The token stays in the environment.
set -eu
if [ -z "${GITLAB_PERSONAL_ACCESS_TOKEN:-}" ]; then
  echo "GITLAB_PERSONAL_ACCESS_TOKEN is not set" >&2
  exit 1
fi
export GITLAB_API_URL="${GITLAB_API_URL:-https://gitlab.com/api/v4}"
NPX=${NPX:-"$HOME/.nvm/versions/node/v24.12.0/bin/npx"}
exec "$NPX" -y @modelcontextprotocol/server-gitlab
