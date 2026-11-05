#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

ROOT=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
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

link_force "$ROOT/skills/zstack" "$HOME_DIR/.cursor/skills/zstack"
link_force "$ROOT/skills/zstack" "$HOME_DIR/.config/opencode/skills/zstack"
link_new "$ROOT/skills/zstack" "$HOME_DIR/.agents/skills/zstack"
link_force "$ROOT/skills/route-work" "$HOME_DIR/.cursor/skills/route-work"
for w in zgrill zspec ztickets zpr zretro to-techspec blast-radius; do
  link_force "$ROOT/skills/$w" "$HOME_DIR/.cursor/skills/$w"
  link_force "$ROOT/skills/$w" "$HOME_DIR/.config/opencode/skills/$w"
done
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

for dir in "$HOME_DIR/.cursor/skills" "$HOME_DIR/.config/opencode/skills"; do
  [ -d "$dir" ] || continue
  for l in "$dir"/*; do
    if [ -L "$l" ] && [ ! -e "$l" ]; then rm "$l"; echo "unlink broken $l"; fi
  done
done

git -C "$ROOT" config core.hooksPath .githooks

link_force "$ROOT/rules/zstack.mdc" "$HOME_DIR/.cursor/rules/zstack.mdc"
link_force "$ROOT/rules/zstack.mdc" "$HOME_DIR/.config/opencode/zstack.md"

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

link_force "$ROOT/agents/opencode/zstack.md" "$HOME_DIR/.config/opencode/agents/zstack.md"

if [ -d "$HOME_DIR/.agents/skills" ]; then
  for src in "$HOME_DIR/.agents/skills"/*; do
    [ -d "$src" ] || continue
    name=$(basename "$src")
    link_new "$src" "$HOME_DIR/.cursor/skills/$name"
    link_new "$src" "$HOME_DIR/.config/opencode/skills/$name"
  done
fi

pstack_skills=$(find "$HOME_DIR/.cursor/plugins/cache/cursor-public/pstack" -type f -path '*/skills/*/SKILL.md' -exec dirname {} \; 2>/dev/null || true)
for src in $pstack_skills; do
  name=$(basename "$src")
  dest="$HOME_DIR/.config/opencode/skills/$name"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    dest="$HOME_DIR/.config/opencode/skills/pstack-$name"
  fi
  link_new "$src" "$dest"
done
