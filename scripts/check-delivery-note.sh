#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
  echo "usage: scripts/check-delivery-note.sh <note>" >&2
  exit 2
fi

note=$1
home_short=$(printf '\176/')
tools='zstack|zninja|zsensei|zigl|zgrill|zspec|ztickets|zretro|poteto-mode|poteto|opencode|obsidian|agent-workflow|grok-|gpt-|claude-|sonnet'
words='(^|[^A-Za-z0-9_])(cursor|kdb|zpr)([^A-Za-z0-9_]|$)'
paths="${home_short}|/Users/|/home/|[.]scratch/|[.]atl/|[.]cursor/|BORRAR ANTES DE ENVIAR"

if hits=$(grep -nEi -e "$tools" -e "$words" -e "$paths" -- "$note"); then
  printf '%s\n' "$hits" >&2
  echo "fail delivery-note: internal mention in $note" >&2
  exit 1
fi
echo "ok delivery-note: $note"
