#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

usage() {
  printf '%s\n' 'usage: scripts/check-topic-repos.sh --kdb <file> --draft <file> [--present <dir> ...]' >&2
  exit 2
}

ere() {
  printf '%s' "$1" | sed -e 's/[][\\.^$*+?(){}|]/\\&/g'
}

draft=
kdb=
present_list=$(mktemp)
trap 'rm -f "$present_list"' EXIT

while [ "$#" -gt 0 ]; do
  case $1 in
    --kdb)
      [ "$#" -ge 2 ] && [ -z "$kdb" ] || usage
      kdb=$2
      shift 2
      ;;
    --draft)
      [ "$#" -ge 2 ] && [ -z "$draft" ] || usage
      draft=$2
      shift 2
      ;;
    --present)
      [ "$#" -ge 2 ] || usage
      shift
      while [ "$#" -gt 0 ]; do
        case $1 in
          --*) break ;;
        esac
        base=${1%/}
        printf '%s\n' "${base##*/}" >> "$present_list"
        shift
      done
      ;;
    *)
      usage
      ;;
  esac
done

[ -n "$kdb" ] && [ -n "$draft" ] || usage
if [ ! -f "$draft" ]; then
  printf '%s\n' "fail topic: $draft is not a file" >&2
  exit 1
fi
if [ ! -f "$kdb" ]; then
  printf '%s\n' "fail topic: $kdb is not a file" >&2
  exit 1
fi

in=0
while IFS= read -r line || [ -n "$line" ]; do
  if [ "$in" -eq 0 ]; then
    if [ "$line" = '```topics' ]; then
      in=1
    fi
    continue
  fi
  if [ "$line" = '```' ]; then
    in=0
    continue
  fi
  [ -n "$line" ] || continue
  extra=
  IFS='	' read -r tema words repo extra <<ROW
$line
ROW
  if [ -z "$tema" ] || [ -z "$words" ] || [ -z "$repo" ] || [ -n "${extra:-}" ]; then
    printf '%s\n' 'fail topic: want <tema><tab><words,comma><tab><repo>' >&2
    exit 2
  fi
  if grep -qxF "$repo" "$present_list"; then
    continue
  fi
  oldifs=$IFS
  set -f
  IFS=,
  for kw in $words; do
    IFS=$oldifs
    set +f
    [ -n "$kw" ] || continue
    while IFS= read -r dline || [ -n "$dline" ]; do
      [ -n "$dline" ] || continue
      if printf '%s\n' "$dline" | grep -iE "(^|[^[:alnum:]_])$(ere "$kw")([^[:alnum:]_]|$)" >/dev/null; then
        if ! printf '%s\n' "$dline" | grep -qE "^Q[0-9]+\\. "; then
          printf '%s\n' "fail topic $tema: concluded without repo $repo" >&2
          exit 1
        fi
        if ! printf '%s\n' "$dline" | grep -qE "repo-ausente: $(ere "$repo")([[:space:]]|$)"; then
          printf '%s\n' "fail topic $tema: concluded without repo $repo" >&2
          exit 1
        fi
      fi
    done < "$draft"
    set -f
    IFS=,
  done
  IFS=$oldifs
  set +f
done < "$kdb"

printf '%s\n' "ok topic: $draft"
