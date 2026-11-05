#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ] || [ ! -f "$1" ]; then
  echo "usage: scripts/check-techspec-paths.sh <markdown> [repo-root]" >&2
  exit 2
fi

note=$1
if [ "$#" -eq 2 ]; then
  root=$2
else
  root=$(git -C "$(dirname "$note")" rev-parse --show-toplevel 2>/dev/null || true)
fi
if [ -z "$root" ] || [ ! -d "$root" ]; then
  echo "fail techspec-paths: repo root is missing for $note" >&2
  exit 2
fi

fail=0
report() {
  printf '%s:%s: %s\n' "$note" "$1" "$2" >&2
  fail=1
}

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

awk '
function trim(s) {
  sub(/^[[:space:]]+/, "", s)
  sub(/[[:space:]]+$/, "", s)
  return s
}
function strip_anchor(s) {
  sub(/#.*$/, "", s)
  sub(/:[0-9]+-[0-9]+$/, "", s)
  sub(/:[0-9]+:[0-9]+$/, "", s)
  sub(/:[0-9]+$/, "", s)
  return s
}
function consider(s,   t, norm) {
  t = trim(s)
  if (t ~ /:\/\//) return
  if (t ~ /[[:space:]]/) return
  if (t ~ /^#/ || t ~ /^mailto:/) return
  t = strip_anchor(t)
  t = trim(t)
  if (t == "") return
  if (t ~ /^\// || t ~ /^~(\/|$)/ || t ~ /^[A-Za-z]:/) {
    printf "%d\tabsolute\t%s\n", NR, t
    return
  }
  norm = t
  gsub(/\\/, "/", norm)
  if (norm ~ /(^|\/)\.\.(\/|$)/) {
    printf "%d\tescape\t%s\n", NR, norm
    return
  }
  if (norm ~ /\// || norm ~ /^[^/]+\.[A-Za-z][A-Za-z0-9]*$/) {
    sub(/\/+$/, "", norm)
    if (norm == "" || norm == ".") return
    printf "%d\trelative\t%s\n", NR, norm
  }
}
function spans(rest,   chunk) {
  while (match(rest, /`[^`]+`/)) {
    chunk = substr(rest, RSTART + 1, RLENGTH - 2)
    consider(chunk)
    rest = substr(rest, RSTART + RLENGTH)
  }
}
function links(rest,   chunk) {
  while (match(rest, /\]\([^)]+\)/)) {
    chunk = substr(rest, RSTART + 2, RLENGTH - 3)
    consider(chunk)
    rest = substr(rest, RSTART + RLENGTH)
  }
}
{
  if (fence) {
    if ($0 ~ /^```/) fence = 0
    next
  }
  if ($0 ~ /^```/) { fence = 1; next }
  spans($0)
  links($0)
}
' "$note" > "$tmp"

while IFS="$(printf '\t')" read -r lineno class path; do
  [ -n "${lineno:-}" ] || continue
  case $class in
    absolute) report "$lineno" "absolute machine path: $path" ;;
    escape) report "$lineno" "escapes the repo root: $path" ;;
    relative)
      if [ ! -e "$root/$path" ]; then
        report "$lineno" "not found from repo root: $path"
      fi
      ;;
    *) report "$lineno" "not found from repo root: $path" ;;
  esac
done < "$tmp"

if [ "$fail" -ne 0 ]; then
  echo "fail techspec-paths: $note" >&2
  exit 1
fi
echo "ok techspec-paths: $note"
