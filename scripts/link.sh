#!/bin/sh
# Point user-level Cursor and OpenCode folders at this repo.
# Adds new directories under ~/.agents/skills only when that name is absent.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
HOME_DIR=${HOME:?}

link_new() {
  src=$1
  dest=$2
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    echo "keep $dest"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  echo "link $dest"
}

link_force() {
  src=$1
  dest=$2
  mkdir -p "$(dirname "$dest")"
  ln -sfn "$src" "$dest"
  echo "link $dest"
}

# Skills published from this repo.
link_force "$ROOT/skills/zstack" "$HOME_DIR/.cursor/skills/zstack"
link_force "$ROOT/skills/zstack" "$HOME_DIR/.config/opencode/skills/zstack"
link_new "$ROOT/skills/zstack" "$HOME_DIR/.agents/skills/zstack"
link_force "$ROOT/skills/route-work" "$HOME_DIR/.cursor/skills/route-work"
link_force "$ROOT/skills/route-work" "$HOME_DIR/.config/opencode/skills/route-work"

for old in \
  "$HOME_DIR/.cursor/rules/route-work.mdc" \
  "$HOME_DIR/.config/opencode/route-work.md" \
  "$HOME_DIR/.config/opencode/agents/route-work.md" \
  "$HOME_DIR/.cursor/agents/implementer.md" "$HOME_DIR/.config/opencode/agents/implementer.md" \
  "$HOME_DIR/.cursor/agents/code-reviewer.md" "$HOME_DIR/.config/opencode/agents/code-reviewer.md" \
  "$HOME_DIR/.cursor/agents/coordinator.md" "$HOME_DIR/.config/opencode/agents/coordinator.md"
do
  case $(readlink "$old" 2>/dev/null || true) in
    "$ROOT"/*) rm "$old"; echo "unlink $old" ;;
  esac
done

git -C "$ROOT" config core.hooksPath .githooks

# Always-on entry: every new session starts with zstack.
link_force "$ROOT/rules/zstack.mdc" "$HOME_DIR/.cursor/rules/zstack.mdc"
link_force "$ROOT/rules/zstack.mdc" "$HOME_DIR/.config/opencode/zstack.md"

# Agents published from this repo. Never replace a file that is already there
# unless it is already a symlink we own.
for agent in zigl zninja zsensei; do
  src="$ROOT/agents/$agent.md"
  for dest in \
    "$HOME_DIR/.cursor/agents/$agent.md" \
    "$HOME_DIR/.config/opencode/agents/$agent.md"
  do
    if [ -L "$dest" ] || [ ! -e "$dest" ]; then
      mkdir -p "$(dirname "$dest")"
      ln -sfn "$src" "$dest"
      echo "link $dest"
    else
      echo "keep $dest (regular file; back it up and remove it to link)"
    fi
  done
done

# OpenCode-only primary agent: the default orchestrator.
link_force "$ROOT/agents/opencode/zstack.md" "$HOME_DIR/.config/opencode/agents/zstack.md"

# Matt skills already installed under ~/.agents/skills: mirror any that
# are missing from the Cursor and OpenCode skill folders.
if [ -d "$HOME_DIR/.agents/skills" ]; then
  for src in "$HOME_DIR/.agents/skills"/*; do
    [ -d "$src" ] || continue
    name=$(basename "$src")
    link_new "$src" "$HOME_DIR/.cursor/skills/$name"
    link_new "$src" "$HOME_DIR/.config/opencode/skills/$name"
  done
fi

# pstack skills live in the Cursor plugin cache. Link them into OpenCode
# under pstack-<name> when the plain name is already taken.
pstack_skills=$(find "$HOME_DIR/.cursor/plugins/cache/cursor-public/pstack" -type f -path '*/skills/*/SKILL.md' -exec dirname {} \; 2>/dev/null || true)
for src in $pstack_skills; do
  name=$(basename "$src")
  dest="$HOME_DIR/.config/opencode/skills/$name"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    dest="$HOME_DIR/.config/opencode/skills/pstack-$name"
  fi
  link_new "$src" "$dest"
done
