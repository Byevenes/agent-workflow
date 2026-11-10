#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

usage() {
  printf '%s\n' 'usage: scripts/check-client-surface.sh <deliverable> [private]' >&2
  exit 2
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  usage
fi

deliverable=$1
if [ "$#" -eq 2 ]; then
  private=$2
else
  private=.scratch/privado.md
fi

if [ ! -f "$deliverable" ]; then
  printf '%s\n' "fail surface: $deliverable is not a file" >&2
  exit 1
fi

if [ ! -f "$private" ]; then
  printf '%s\n' 'fail surface: write .scratch/privado.md (even if ninguno)' >&2
  exit 1
fi

while IFS= read -r line || [ -n "$line" ]; do
  case $line in
    *INTERNO:*)
      printf '%s\n' 'fail surface: INTERNO line belongs in the private file' >&2
      exit 1
      ;;
  esac
  case $line in
    *'BEGIN OPENSSH'*|*'BEGIN PRIVATE KEY'*)
      printf '%s\n' 'fail surface: key block belongs in the private file' >&2
      exit 1
      ;;
  esac
done < "$deliverable"

printf '%s\n' "ok surface: $deliverable"
