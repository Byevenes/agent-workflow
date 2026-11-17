#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

usage() {
  echo "usage: scripts/mode-for.sh <path>" >&2
  exit 2
}

[ "$#" -eq 1 ] || usage
target=$(cd "$1" 2>/dev/null && pwd -P) || { echo "fail: not a directory: $1" >&2; exit 2; }

expand_home() {
  case $1 in
    \~) printf '%s\n' "$HOME" ;;
    \~/*) printf '%s/%s\n' "$HOME" "${1#\~/}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

real_dir() {
  (cd "$1" 2>/dev/null && pwd -P) || printf '%s\n' "$1"
}

path_under() {
  [ -n "$1" ] || return 1
  [ "$2" = "$1" ] && return 0
  [ "${2#"$1"/}" != "$2" ]
}

rank() {
  case $1 in
    plan-only) echo 0 ;;
    ask-first) echo 1 ;;
    accept-edits) echo 2 ;;
    *) return 1 ;;
  esac
}

cmap=${ZSTACK_CLIENTS_TOML:-$HOME/.config/zstack/clients.toml}
map_root=
best_len=0
mode=
source=

if [ -f "$cmap" ]; then
  rows=$(awk '
    function qval(v) { sub(/^"/, "", v); sub(/"[[:space:]]*(#.*)?$/, "", v); return v }
    function flush() { if (section && root != "") printf "C\t%s\t%s\n", root, m }
    /^[[:space:]]*\[/ { flush(); section = ($0 ~ /^[[:space:]]*\[clients\./); root = ""; m = ""; next }
    /^[[:space:]]*#/ { next }
    {
      line = $0
      if (match(line, /^[[:space:]]*[A-Za-z_]+[[:space:]]*=/)) {
        key = substr(line, RSTART, RLENGTH); sub(/[[:space:]]*=$/, "", key); gsub(/[[:space:]]/, "", key)
        val = substr(line, RSTART + RLENGTH); sub(/^[[:space:]]*/, "", val)
        if (!section && key == "clients_root") printf "R\t%s\t\n", qval(val)
        if (section && key == "root") root = qval(val)
        if (section && key == "mode") m = qval(val)
      }
    }
    END { flush() }' "$cmap")
  tab=$(printf '\t')
  while IFS=$tab read -r kind r m; do
    case $kind in
      R) map_root=$r ;;
      C)
        cr=$(real_dir "$(expand_home "$r")")
        if path_under "$cr" "$target" && [ "${#cr}" -gt "$best_len" ]; then
          best_len=${#cr}
          if [ -n "$m" ]; then
            rank "$m" >/dev/null || { echo "fail: unknown mode \"$m\" for root $r in $cmap" >&2; exit 2; }
            mode=$m; source="clients.toml $r"
          else
            mode=ask-first; source="client root $r, no mode set"
          fi
        fi
        ;;
    esac
  done <<ROWS
$rows
ROWS
fi

if [ -z "$mode" ]; then
  if [ -n "${CLIENTS_ROOT:-}" ]; then croot=$(expand_home "$CLIENTS_ROOT")
  elif [ -n "$map_root" ]; then croot=$(expand_home "$map_root")
  else croot=$HOME/Clients; fi
  croot=$(real_dir "$croot")
  if path_under "$croot" "$target"; then
    mode=ask-first; source="clients root"
  else
    mode=accept-edits; source="personal default"
  fi
fi

if [ -n "${ZSTACK_MODE:-}" ]; then
  want=$(rank "$ZSTACK_MODE") || { echo "fail: unknown ZSTACK_MODE \"$ZSTACK_MODE\"" >&2; exit 2; }
  have=$(rank "$mode")
  if [ "$want" -lt "$have" ]; then
    mode=$ZSTACK_MODE; source="ZSTACK_MODE (stricter)"
  elif [ "$want" -gt "$have" ]; then
    echo "warn: ZSTACK_MODE=$ZSTACK_MODE is looser than $mode; ignored" >&2
  fi
fi

printf 'mode: %s (%s)\n' "$mode" "$source"
