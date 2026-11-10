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

conn_fail='fail surface: connection string in the deliverable'
conn_uri='(postgres(ql)?|mysql|mariadb|mongodb(\+srv)?|rediss?|amqps?|mssql|sqlserver|oracle|neo4j|bolt|couchbase|cassandra)://|jdbc:(postgresql|mysql|mariadb|oracle|sqlserver|jtds):|://[^ :/@]+:[^ @]+@'
conn_secret='(^|[^[:alnum:]_])(password|pwd)[[:space:]]*='
conn_where='(^|[^[:alnum:]_])(data source|user id|username|user|uid|host|server)[[:space:]]*='

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
  status=0
  printf '%s\n' "$line" | grep -E -i -q -e "$conn_uri" || status=$?
  if [ "$status" -ne 1 ]; then
    printf '%s\n' "$conn_fail" >&2
    exit 1
  fi
  status=0
  printf '%s\n' "$line" | grep -E -i -q -e "$conn_secret" || status=$?
  if [ "$status" -eq 0 ]; then
    where=0
    printf '%s\n' "$line" | grep -E -i -q -e "$conn_where" || where=$?
    if [ "$where" -ne 1 ]; then
      printf '%s\n' "$conn_fail" >&2
      exit 1
    fi
  elif [ "$status" -ne 1 ]; then
    printf '%s\n' "$conn_fail" >&2
    exit 1
  fi
done < "$deliverable"

printf '%s\n' "ok surface: $deliverable"
