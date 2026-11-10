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
sh "$bin/check-client-surface.sh" "$draft" || fail=1

check_topic_kdb() {
  kdb=$1
  if [ -f .scratch/present-repos.txt ]; then
    set -- --kdb "$kdb" --draft "$draft"
    while IFS= read -r dir || [ -n "$dir" ]; do
      [ -n "$dir" ] || continue
      set -- "$@" --present "$dir"
    done < .scratch/present-repos.txt
    sh "$bin/check-topic-repos.sh" "$@"
  else
    sh "$bin/check-topic-repos.sh" --kdb "$kdb" --draft "$draft"
  fi
}

if [ -f .scratch/kdb-used.txt ]; then
  side_line=
  IFS= read -r side_line < .scratch/kdb-used.txt || true
  case $side_line in
    'kdb: none found ('*')') ;;
    'kdb: '*)
      rest=${side_line#'kdb: '}
      while :; do
        case $rest in
          *', '*)
            path=${rest%%', '*}
            rest=${rest#*', '}
            more=1
            ;;
          *)
            path=$rest
            more=0
            ;;
        esac
        case $path in
          ' '*) path=${path# } ;;
        esac
        case $path in
          *' ') path=${path% } ;;
        esac
        if [ -n "$path" ] && [ -f "$path" ]; then
          check_topic_kdb "$path" || fail=1
        fi
        if [ "$more" -eq 0 ]; then
          break
        fi
        if [ -z "$rest" ]; then
          break
        fi
      done
      ;;
  esac
fi
exit "$fail"
