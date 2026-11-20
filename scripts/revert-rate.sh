#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

usage() {
  printf '%s\n' 'usage: scripts/revert-rate.sh [-C <repo>] [--since <date>] [--until <date>] [--branch <ref>]' >&2
  exit 2
}

report() {
  p=$(LC_ALL=C awk -v n="$1" -v r="$2" 'BEGIN { if (n + 0 == 0) printf "0.0"; else printf "%.1f", (r / n) * 100 }')
  printf 'changes %s, reverts %s, rate %s%%\n' "$1" "$2" "$p"
  if [ "$2" -gt 0 ]; then
    cat "$3"
  fi
  printf 'revert-rate changes=%s reverts=%s rate=%s\n' "$1" "$2" "$p"
}

repo=
since=
until=
branch=
while [ "$#" -gt 0 ]; do
  case $1 in
    -C|--since|--until|--branch)
      if [ "$#" -lt 2 ] || [ -z "$2" ]; then
        usage
      fi
      case $1 in
        -C)
          [ -z "$repo" ] || usage
          repo=$2
          ;;
        --since)
          [ -z "$since" ] || usage
          since=$2
          ;;
        --until)
          [ -z "$until" ] || usage
          until=$2
          ;;
        --branch)
          [ -z "$branch" ] || usage
          branch=$2
          ;;
      esac
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

[ -n "$repo" ] || repo=.
[ -n "$since" ] || since='30 days ago'
[ -d "$repo" ] || exit 2
git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 2

if [ -z "$branch" ]; then
  if git -C "$repo" rev-parse --verify --quiet origin/HEAD >/dev/null 2>&1; then
    branch=origin/HEAD
  elif git -C "$repo" rev-parse --verify --quiet HEAD >/dev/null 2>&1; then
    branch=HEAD
  else
    report 0 0 /dev/null
    exit 0
  fi
elif ! git -C "$repo" rev-parse --verify --quiet "$branch" >/dev/null 2>&1; then
  exit 2
fi

set -- --first-parent --since="$since"
if [ -n "$until" ]; then
  set -- "$@" --until="$until"
fi
set -- "$@" "$branch"
hashes=$(git -C "$repo" rev-list "$@" 2>/dev/null) || exit 2

list=$(mktemp)
trap 'rm -f "$list"' EXIT
n=0
r=0
while IFS= read -r c || [ -n "$c" ]; do
  [ -n "$c" ] || continue
  n=$((n + 1))
  subject=$(git -C "$repo" log -1 --format=%s "$c" 2>/dev/null) || exit 2
  short=$(printf '%.7s' "$c")
  hit=0
  case "$subject" in
    'Revert "'*) hit=1 ;;
  esac
  if [ "$hit" -eq 0 ]; then
    body=$(git -C "$repo" log -1 --format=%b "$c" 2>/dev/null) || exit 2
    if printf '%s\n' "$body" | grep -F -q 'This reverts commit '; then
      hit=1
    fi
  fi
  if [ "$hit" -eq 1 ]; then
    r=$((r + 1))
    printf '%s %s\n' "$short" "$subject" >>"$list"
  fi
done <<EOF
$hashes
EOF

report "$n" "$r" "$list"
