#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

want='fail kdb: want one line kdb: <files read> or kdb: none found (<reason>)'

if [ "$#" -gt 1 ]; then
  printf '%s\n' 'usage: scripts/check-prestage-kdb.sh [sidecar]' >&2
  exit 2
fi

if [ "$#" -eq 1 ]; then
  sidecar=$1
else
  sidecar=.scratch/kdb-used.txt
fi

if [ ! -f "$sidecar" ]; then
  printf '%s\n' "fail kdb: missing $sidecar; write kdb: <files read> or kdb: none found (<reason>)" >&2
  exit 1
fi

nl=0
line=
while IFS= read -r got || [ -n "$got" ]; do
  nl=$((nl + 1))
  if [ "$nl" -eq 1 ]; then
    line=$got
  fi
  if [ "$nl" -gt 1 ]; then
    break
  fi
done < "$sidecar"

if [ "$nl" -ne 1 ]; then
  printf '%s\n' "$want" >&2
  exit 1
fi

case $line in
  'kdb: none found ('*')')
    reason=${line#'kdb: none found ('}
    reason=${reason%')'}
    case $reason in
      ' '*) reason=${reason# } ;;
    esac
    case $reason in
      *' ') reason=${reason% } ;;
    esac
    if [ -z "$reason" ]; then
      printf '%s\n' 'fail kdb: none found needs a reason' >&2
      exit 1
    fi
    printf '%s\n' "ok kdb: $sidecar"
    exit 0
    ;;
esac

case $line in
  'kdb: '*) ;;
  *)
    printf '%s\n' "$want" >&2
    exit 1
    ;;
esac

rest=${line#'kdb: '}
if [ -z "$rest" ]; then
  printf '%s\n' "$want" >&2
  exit 1
fi

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
  if [ ! -f "$path" ]; then
    printf '%s\n' "fail kdb: $path is not a file" >&2
    exit 1
  fi
  if [ "$more" -eq 0 ]; then
    break
  fi
  if [ -z "$rest" ]; then
    printf '%s\n' 'fail kdb:  is not a file' >&2
    exit 1
  fi
done

printf '%s\n' "ok kdb: $sidecar"
