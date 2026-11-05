#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

usage() {
  echo "usage: scripts/classify-test-failures.sh <head-results> [base-results]" >&2
  exit 2
}

if [ "$#" -eq 1 ]; then
  head=$1
  base=
  has=0
elif [ "$#" -eq 2 ]; then
  head=$1
  base=$2
  has=1
else
  usage
fi

if [ ! -f "$head" ]; then
  echo "classify-test-failures: not a file: $head" >&2
  exit 2
fi
if [ "$has" -eq 1 ] && [ ! -f "$base" ]; then
  echo "classify-test-failures: not a file: $base" >&2
  exit 2
fi

tmp=$(mktemp)
errf=$(mktemp)
trap 'rm -f "$tmp" "$errf"' EXIT

set +e
BR_HAS_BASE=$has BR_HEAD=$head BR_BASE=$base awk '
function die(msg, code) {
  printf "classify-test-failures: %s\n", msg > "/dev/stderr"
  exit code
}
function load(path, kind,    line, rc, i, n, status, id, rest) {
  while (1) {
    rc = (getline line < path)
    if (rc == 0) break
    if (rc < 0) die("cannot read " path, 2)
    sub(/\r$/, "", line)
    if (line ~ /^[[:space:]]*$/) continue
    n = length(line)
    i = 1
    status = ""
    while (i <= n && substr(line, i, 1) !~ /[[:space:]]/) {
      status = status substr(line, i, 1)
      i++
    }
    while (i <= n && substr(line, i, 1) ~ /[[:space:]]/) i++
    id = ""
    while (i <= n && substr(line, i, 1) !~ /[[:space:]]/) {
      id = id substr(line, i, 1)
      i++
    }
    if (status != "PASS" && status != "FAIL") die("bad status in " path, 2)
    if (id == "") die("missing id in " path, 2)
    rest = ""
    if (i <= n) {
      while (i <= n && substr(line, i, 1) ~ /[[:space:]]/) i++
      rest = substr(line, i)
    }
    if (kind == "base") {
      base_status[id] = status
      base_detail[id] = rest
    } else {
      head_status[id] = status
      head_detail[id] = rest
    }
  }
  close(path)
}
BEGIN {
  has_base = ENVIRON["BR_HAS_BASE"] + 0
  load(ENVIRON["BR_HEAD"], "head")
  if (has_base) load(ENVIRON["BR_BASE"], "base")
  for (id in head_status) {
    if (head_status[id] != "FAIL") continue
    if (has_base && (id in base_status) && base_status[id] == "FAIL" && base_detail[id] == head_detail[id])
      kind = "env-known"
    else
      kind = "real"
    printf "%s\t%s\t%s\n", kind, id, head_detail[id]
  }
}
' >"$tmp" 2>"$errf"
st=$?
set -e
if [ "$st" -ne 0 ]; then
  cat "$errf" >&2
  exit "$st"
fi

LC_ALL=C sort -o "$tmp" "$tmp"
cat "$tmp"
tab=$(printf '\t')
if grep -q "^real${tab}" "$tmp"; then
  exit 1
fi
