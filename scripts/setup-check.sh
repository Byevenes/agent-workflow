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

check_link "$HOME/.cursor/skills/route-work"
check_link "$HOME/.config/opencode/skills/route-work"
check_link "$HOME/.cursor/agents/coordinator.md"
check_link "$HOME/.config/opencode/agents/coordinator.md"
check_link "$HOME/.cursor/plugins/cache/cursor-public/pstack"
check_link "$ROOT/skills/route-work/SKILL.md"
check_link "$HOME/.cursor/rules/route-work.mdc"
check_link "$HOME/.cursor/agents/implementer.md"
if grep -q "route-work.md" "$HOME/.config/opencode/opencode.json" 2>/dev/null; then echo "ok opencode instructions route-work"; else echo "todo opencode: add ~/.config/opencode/route-work.md to \"instructions\" in opencode.json"; fi

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
