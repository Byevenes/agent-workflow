#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

usage() {
  echo "usage: scripts/sonar-diff-issues.sh <base> <issues.json>" >&2
  echo "       scripts/sonar-diff-issues.sh <base> --fetch <project-key>" >&2
  exit 2
}

[ "$#" -ge 2 ] || usage
base=$1
shift
git rev-parse --verify --quiet "$base^{commit}" >/dev/null || { echo "fail: unknown base $base" >&2; exit 2; }
command -v jq >/dev/null || { echo "fail: jq is required" >&2; exit 2; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

if [ "$1" = "--fetch" ]; then
  [ "$#" -eq 2 ] || usage
  key=$2
  host=${SONAR_HOST_URL:-http://localhost:9000}
  if ! curl -fsS --max-time 5 "$host/api/system/status" 2>/dev/null | grep -q '"status":"UP"'; then
    echo "skip: no SonarQube answering at $host" >&2
    exit 3
  fi
  [ -n "${SONAR_TOKEN:-}" ] || { echo "fail: SONAR_TOKEN is not set (load it from your personal tooling env file)" >&2; exit 2; }
  printf 'user = "%s:"\n' "$SONAR_TOKEN" | curl -fsS -K - --max-time 30 \
    "$host/api/issues/search?componentKeys=$key&resolved=false&ps=500" > "$tmp/issues.json" \
    || { echo "fail: issue search failed for $key" >&2; exit 2; }
  json=$tmp/issues.json
else
  [ "$#" -eq 1 ] || usage
  json=$1
  [ -f "$json" ] || { echo "fail: missing $json" >&2; exit 2; }
fi

total=$(jq -r '.total // (.issues | length)' "$json") || { echo "fail: not issue JSON: $json" >&2; exit 2; }
[ "$total" -le 500 ] || echo "warn: $total open issues, only the first 500 were read" >&2

git diff -U0 --no-color --no-ext-diff "$base"...HEAD | awk '
  /^\+\+\+ / { f = substr($0, 5); sub(/^b\//, "", f); next }
  /^@@ / {
    split($3, p, ",")
    start = substr(p[1], 2) + 0
    n = (2 in p) ? p[2] + 0 : 1
    for (i = 0; i < n; i++) printf "%s\t%d\n", f, start + i
  }' > "$tmp/changed.tsv"

jq -r '.issues[] | select(.line != null)
  | [(.component | sub("^[^:]*:"; "")), (.line | tostring), (.severity // "-"), .rule, (.message | gsub("[\t\n]"; " "))]
  | @tsv' "$json" > "$tmp/issues.tsv"

awk -F '\t' 'NR == FNR { ch[$1 "\t" $2] = 1; next }
  ($1 "\t" $2) in ch { printf "%s:%s\t%s\t%s\t%s\n", $1, $2, $3, $4, $5; hit = 1 }
  END { exit hit ? 1 : 0 }' "$tmp/changed.tsv" "$tmp/issues.tsv"
