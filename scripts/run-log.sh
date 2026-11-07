#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

tab=$(printf '\t')

usage() {
  echo "usage: scripts/run-log.sh append --task <text> --model <text> --checks <text> --result <text> --cost <text> | show [<id>]" >&2
  exit 2
}

die() {
  printf 'run-log: %s\n' "$1" >&2
  exit "$2"
}

has_break() {
  case $1 in
    *"$tab"*) return 0 ;;
  esac
  before=$(printf '%s' "$1" | wc -c)
  after=$(printf '%s' "$1" | tr -d '\n' | wc -c)
  [ "$before" != "$after" ]
}

valid_id() {
  case $1 in
    ''|*[!0-9]*|0*) return 1 ;;
    *) return 0 ;;
  esac
}

if [ -n "${RUN_ROOT:-}" ]; then
  root=$RUN_ROOT
else
  root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi
scratch=$root/.scratch
log=$scratch/run-log.tsv

next_id() {
  max=0
  if [ -f "$log" ]; then
    m=$(awk -F '\t' 'BEGIN { m = 0 } $1 ~ /^[1-9][0-9]*$/ && $1 + 0 > m { m = $1 + 0 } END { print m + 0 }' "$log")
    if [ "$m" -gt "$max" ]; then
      max=$m
    fi
  fi
  printf '%s\n' "$((max + 1))"
}

do_append() {
  if has_break "$task" || has_break "$model" || has_break "$checks" || has_break "$result" || has_break "$cost"; then
    die "bad field" 2
  fi
  if [ -z "$task" ] || [ -z "$model" ] || [ -z "$checks" ] || [ -z "$result" ] || [ -z "$cost" ]; then
    die "bad field" 2
  fi
  id=$(next_id)
  mkdir -p "$scratch"
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$id" "$task" "$model" "$checks" "$result" "$cost" >> "$log"
  printf '%s\n' "$id"
}

do_show() {
  if [ ! -f "$log" ]; then
    exit 0
  fi
  cat "$log"
}

do_show_id() {
  if ! valid_id "$id"; then
    die "bad id" 2
  fi
  [ -f "$log" ] || die "unknown id" 1
  row=$(awk -F '\t' -v id="$id" '$1 == id { print; exit }' "$log")
  [ -n "$row" ] || die "unknown id" 1
  printf '%s\n' "$row"
}

[ "$#" -ge 1 ] || usage
cmd=$1
shift
case $cmd in
  append)
    if [ "$#" -ne 10 ] || [ "$1" != "--task" ] || [ "$3" != "--model" ] || [ "$5" != "--checks" ] || [ "$7" != "--result" ] || [ "$9" != "--cost" ]; then usage; fi
    task=$2
    model=$4
    checks=$6
    result=$8
    cost=${10}
    do_append
    ;;
  show)
    if [ "$#" -eq 0 ]; then
      do_show
    elif [ "$#" -eq 1 ]; then
      id=$1
      do_show_id
    else
      usage
    fi
    ;;
  *)
    usage
    ;;
esac
