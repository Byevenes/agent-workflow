#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

usage() {
  printf '%s\n' 'usage: scripts/prestage-handoff.sh <analysis|questionnaire> <draft> [--analysis <file>]' >&2
  exit 2
}

if [ "$#" -lt 2 ] || [ "$#" -eq 3 ] || [ "$#" -gt 4 ]; then
  usage
fi

kind=$1
draft=$2
case $kind in
  analysis|questionnaire) ;;
  *) usage ;;
esac

if [ "$#" -eq 4 ]; then
  if [ "$kind" != questionnaire ] || [ "$3" != "--analysis" ]; then
    usage
  fi
  set -- "$kind" "$draft" --analysis "$4"
else
  set -- "$kind" "$draft"
fi

bin=$(dirname "$0")
fail=0
sh "$bin/check-draft-sections.sh" "$@" || fail=1
sh "$bin/check-prestage-kdb.sh" || fail=1
exit "$fail"
