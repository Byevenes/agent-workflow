#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
  echo "usage: scripts/check-required-claims.sh <draft.md>" >&2
  exit 2
fi

awk '
  /^```/ { fence = !fence; next }
  fence { next }
  {
    l = tolower($0)
    if (l ~ /(obligatori|requerid|not null|no nulo|no acepta nulos|non-null|required|mandatory)/ && l ~ /(columna|campo|column|field|propiedad|property|par[aá]metro|parameter|atributo|attribute)/ && l !~ /fuente:/) {
      printf "fail required-claim line %d: cite the evidence with fuente: (schema, migration or query)\n", NR
      bad = 1
    }
  }
  END { exit bad ? 1 : 0 }' "$1"
