#!/bin/sh
set -eu
if [ -z "${POSTGRES_URL:-}" ]; then
  echo "POSTGRES_URL is not set" >&2
  exit 1
fi
NPX=${NPX:-"$HOME/.nvm/versions/node/v24.12.0/bin/npx"}
exec "$NPX" -y @modelcontextprotocol/server-postgres "$POSTGRES_URL"
