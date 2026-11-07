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

pin_file=$ROOT/skills/versions
if [ -n "${LINK_SKILL_VERSIONS:-}" ]; then
  pin_file=$LINK_SKILL_VERSIONS
fi
if [ ! -f "$pin_file" ]; then
  echo "link.sh: pin file missing: $pin_file" >&2
  exit 1
fi
skill_src=''

require_skill_rev() {
  _name=$1
  _rev=$2
  if ! git -C "$ROOT" cat-file -e "${_rev}:skills/${_name}/SKILL.md"; then
    echo "link.sh: $_name at $_rev has no skills/$_name/SKILL.md" >&2
    exit 1
  fi
}

while IFS= read -r _line || [ -n "${_line:-}" ]; do
  _name=${_line%%[[:space:]]*}
  _rest=${_line#"$_name"}
  _rest=${_rest#"${_rest%%[![:space:]]*}"}
  _rev=${_rest%%[[:space:]]*}
  _line=
  [ -n "$_name" ] || continue
  case "$_rev" in
    ''|main|HEAD) continue ;;
  esac
  require_skill_rev "$_name" "$_rev"
done < "$pin_file"

resolve_skill() {
  _name=$1
  _rev=$(awk -v n="$_name" 'NF > 0 && $1 == n { print $2; exit }' "$pin_file")
  case "$_rev" in
    ''|main|HEAD)
      skill_src="$ROOT/skills/$_name"
      return 0
      ;;
  esac
  require_skill_rev "$_name" "$_rev"
  _safe=$(printf '%s' "$_rev" | tr '/' '_')
  _cache="$HOME_DIR/.cache/agent-workflow/skills/$_name/$_safe"
  if [ -f "$_cache/SKILL.md" ]; then
    skill_src="$_cache"
    return 0
  fi
  _arc=$(mktemp)
  if ! git -C "$ROOT" archive --format=tar -o "$_arc" "$_rev" "skills/$_name"; then
    rm -f "$_arc"
    echo "link.sh: archive failed for $_name at $_rev" >&2
    exit 1
  fi
  _stage=$(mktemp -d)
  if ! tar -xf "$_arc" -C "$_stage"; then
    rm -f "$_arc"
    rm -rf "$_stage"
    echo "link.sh: extract failed for $_name at $_rev" >&2
    exit 1
  fi
  rm -f "$_arc"
  _tree="$_stage/skills/$_name"
  if [ ! -f "$_tree/SKILL.md" ]; then
    rm -rf "$_stage"
    echo "link.sh: $_name at $_rev has no skill file" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$_cache")"
  rm -rf "$_cache"
  mv "$_tree" "$_cache"
  rm -rf "$_stage"
  skill_src="$_cache"
}

resolve_skill zstack
link_force "$skill_src" "$HOME_DIR/.cursor/skills/zstack"
link_force "$skill_src" "$HOME_DIR/.config/opencode/skills/zstack"
link_new "$skill_src" "$HOME_DIR/.agents/skills/zstack"
resolve_skill route-work
route_src="$skill_src"
link_force "$route_src" "$HOME_DIR/.cursor/skills/route-work"
for w in zgrill zspec ztickets zpr zretro zwrite to-techspec blast-radius; do
  resolve_skill "$w"
  link_force "$skill_src" "$HOME_DIR/.cursor/skills/$w"
  link_force "$skill_src" "$HOME_DIR/.config/opencode/skills/$w"
done
link_force "$route_src" "$HOME_DIR/.config/opencode/skills/route-work"

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

for agent in zigl zninja zsensei; do
  dest="$ROOT/.cursor/agents/$agent.md"
  rel="../../agents/$agent.md"
  if [ -L "$dest" ] || [ ! -e "$dest" ]; then
    mkdir -p "$(dirname "$dest")"
    ln -sfn "$rel" "$dest"
    echo "link .cursor/agents/$agent.md"
  else
    echo "keep .cursor/agents/$agent.md (regular file; back it up and remove it to link)"
  fi
done

plugin_root="$HOME_DIR/.cursor/plugins/local/zstack-agents"
mkdir -p "$plugin_root/.cursor-plugin" "$plugin_root/agents"
cat > "$plugin_root/.cursor-plugin/plugin.json" <<'EOF'
{
  "name": "zstack-agents",
  "version": "0.1.0",
  "description": "zStack subagents zigl, zninja, and zsensei.",
  "agents": "./agents/"
}
EOF
for agent in zigl zninja zsensei; do
  src="$ROOT/agents/$agent.md"
  dest="$plugin_root/agents/$agent.md"
  if [ -L "$dest" ]; then
    rm "$dest"
  fi
  cp "$src" "$dest"
  echo "copy $dest"
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
