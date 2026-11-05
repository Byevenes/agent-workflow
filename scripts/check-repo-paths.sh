#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

if [ "$#" -ne 2 ] || [ ! -f "$1" ] || [ ! -d "$2" ]; then
  echo "usage: scripts/check-repo-paths.sh <markdown> <repo-root>" >&2
  exit 2
fi

note=$1
root=$2
tilde=$(printf '\176')
list=$(mktemp)
trap 'rm -f "$list"' EXIT

awk '
function is_citation(s,    n, i, c, ext) {
  n = length(s)
  if (n == 0) return 0
  if (s ~ /[[:space:]]/) return 0
  if (s ~ /:\/\//) return 0
  if (substr(s, n, 1) == "/") return 1
  ext = ""
  for (i = n; i > 0; i--) {
    c = substr(s, i, 1)
    if (c == ".") {
      ext = substr(s, i + 1)
      break
    }
    if (c == "/") break
  }
  if (length(ext) < 1 || length(ext) > 8) return 0
  c = substr(ext, 1, 1)
  if ((c >= "A" && c <= "Z") || (c >= "a" && c <= "z")) return 1
  return 0
}
BEGIN { fence = 0 }
{
  if ($0 ~ /^[[:space:]]*```/ || $0 ~ /^[[:space:]]*~~~/) {
    fence = !fence
    next
  }
  if (fence) next
  rest = $0
  while (match(rest, /`[^`]+`/)) {
    span = substr(rest, RSTART + 1, RLENGTH - 2)
    rest = substr(rest, RSTART + RLENGTH)
    if (is_citation(span)) printf "%d\t%s\n", NR, span
  }
}
' "$note" > "$list"

fail=0
bad() {
  printf 'fail repo-paths: %s: %s (%s:%s)\n' "$1" "$2" "$note" "$3" >&2
  fail=1
}

is_absolute() {
  span=$1
  case $span in
    /*|"$tilde"*) return 0 ;;
  esac
  printf '%s' "$span" | grep -Eq '^[A-Za-z]:[/\\]'
}

not_canonical() {
  span=$1
  case $span in
    *\\*) return 0 ;;
  esac
  rest=$span
  while [ -n "$rest" ]; do
    case $rest in
      */*) seg=${rest%%/*}; rest=${rest#*/} ;;
      *) seg=$rest; rest= ;;
    esac
    case $seg in
      ""|.|..) return 0 ;;
    esac
  done
  return 1
}

while IFS=$(printf '\t') read -r lineno span || [ -n "${span:-}" ]; do
  [ -n "${span:-}" ] || continue
  if is_absolute "$span"; then
    bad "absolute path" "$span" "$lineno"
    continue
  fi
  if not_canonical "$span"; then
    bad "not a repo-root path" "$span" "$lineno"
    continue
  fi
  if [ ! -e "$root/$span" ]; then
    bad "does not exist from the repo root" "$span" "$lineno"
  fi
done < "$list"

if [ "$fail" -eq 0 ]; then
  printf 'ok repo-paths: %s\n' "$note"
fi
exit "$fail"
