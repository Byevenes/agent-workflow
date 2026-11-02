#!/bin/sh
# Report whether the local setup resolves. Never print secret values.
set -eu

fail=0

need() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "ok command $1"
  else
    echo "missing command $1"
    fail=1
  fi
}

need gh
need herdr
need opencode
need cursor-agent

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)

check_link() {
  path=$1
  if [ -L "$path" ] || [ -e "$path" ]; then
    echo "ok path $path"
  else
    echo "missing path $path"
    fail=1
  fi
}

check_link "$HOME/.cursor/skills/zstack"
check_link "$HOME/.cursor/skills/route-work"
check_link "$HOME/.config/opencode/skills/zstack"
check_link "$HOME/.cursor/agents/zigl.md"
check_link "$HOME/.config/opencode/agents/zigl.md"
check_link "$HOME/.cursor/plugins/cache/cursor-public/pstack"
check_link "$ROOT/skills/zstack/SKILL.md"
check_link "$HOME/.cursor/rules/zstack.mdc"
check_link "$HOME/.cursor/agents/zninja.md"
check_link "$HOME/.cursor/agents/zsensei.md"
check_link "$HOME/.config/opencode/agents/zsensei.md"
check_link "$HOME/.config/opencode/agents/zstack.md"
if grep -q '"default_agent": "zstack"' "$HOME/.config/opencode/opencode.json" 2>/dev/null; then echo "ok opencode default_agent zstack"; else echo "todo opencode: set \"default_agent\": \"zstack\""; fi
if grep -q "zstack.md" "$HOME/.config/opencode/opencode.json" 2>/dev/null; then echo "ok opencode instructions zstack"; else echo "todo opencode: add ~/.config/opencode/zstack.md to \"instructions\" in opencode.json"; fi

if [ -n "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]; then
  echo "ok env GITHUB_PERSONAL_ACCESS_TOKEN"
else
  echo "missing env GITHUB_PERSONAL_ACCESS_TOKEN"
fi

if [ -n "${GITLAB_PERSONAL_ACCESS_TOKEN:-}" ]; then
  echo "ok env GITLAB_PERSONAL_ACCESS_TOKEN"
else
  echo "missing env GITLAB_PERSONAL_ACCESS_TOKEN"
fi

if [ -n "${POSTGRES_URL:-}" ]; then
  echo "ok env POSTGRES_URL"
else
  echo "missing env POSTGRES_URL"
fi

exit "$fail"
