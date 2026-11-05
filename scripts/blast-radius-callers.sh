#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

usage() {
  echo "usage: scripts/blast-radius-callers.sh <graph> <symbol> [--expect <report>]" >&2
  exit 2
}

expect=
if [ "$#" -eq 2 ]; then
  graph=$1
  symbol=$2
elif [ "$#" -eq 4 ] && [ "$3" = "--expect" ]; then
  graph=$1
  symbol=$2
  expect=$4
else
  usage
fi

if [ -z "$symbol" ] || [ ! -f "$graph" ]; then
  usage
fi
if [ -n "$expect" ] && [ ! -f "$expect" ]; then
  echo "blast-radius: not a file: $expect" >&2
  exit 2
fi

tmp=$(mktemp)
errf=$(mktemp)
expf=$(mktemp)
trap 'rm -f "$tmp" "$errf" "$expf"' EXIT

set +e
BR_TARGET=$symbol awk '
function die(msg, code) {
  printf "blast-radius: %s\n", msg > "/dev/stderr"
  err = code
  exit code
}
BEGIN { target = ENVIRON["BR_TARGET"] }
{
  sub(/\r$/, "")
  if (NF == 0) next
  if ($1 == "symbol") {
    if (NF != 5) die("symbol line needs 5 fields at line " NR, 2)
    if ($3 != "public" && $3 != "private") die("visibility at line " NR, 2)
    if ($2 in sym_mod) die("duplicate symbol " $2, 2)
    sym_mod[$2] = $4
    sym_file[$2] = $5
  } else if ($1 == "edge") {
    if (NF != 3) die("edge line needs 3 fields at line " NR, 2)
    nedge++
    edge_from[nedge] = $2
    edge_to[nedge] = $3
  } else {
    die("bad line " NR, 2)
  }
}
END {
  if (err) exit err
  if (!(target in sym_mod)) {
    printf "blast-radius: unknown symbol %s\n", target > "/dev/stderr"
    exit 1
  }
  mod = sym_mod[target]
  for (i = 1; i <= nedge; i++) {
    c = edge_from[i]
    d = edge_to[i]
    if (!(c in sym_mod)) die("unknown caller " c, 2)
    if (!(d in sym_mod)) die("unknown callee " d, 2)
    if (sym_mod[c] != mod || sym_mod[d] != mod) continue
    n = ncallers[d] + 1
    ncallers[d] = n
    caller_at[d, n] = c
  }
  seen[target] = 1
  q[0] = target
  qh = 0
  qt = 1
  while (qh < qt) {
    cur = q[qh]
    qh++
    n = ncallers[cur] + 0
    for (i = 1; i <= n; i++) {
      c = caller_at[cur, i]
      if (seen[c]) continue
      seen[c] = 1
      print sym_file[c], c
      q[qt] = c
      qt++
    }
  }
}
' "$graph" >"$tmp" 2>"$errf"
st=$?
set -e
if [ "$st" -ne 0 ]; then
  cat "$errf" >&2
  exit "$st"
fi

LC_ALL=C sort -o "$tmp" "$tmp"

if [ -n "$expect" ]; then
  awk 'NF { sub(/\r$/, ""); print }' "$expect" | LC_ALL=C sort >"$expf"
  if ! cmp -s "$tmp" "$expf"; then
    echo "blast-radius: report does not cover $symbol" >&2
    echo "in walk only:" >&2
    LC_ALL=C comm -23 "$tmp" "$expf" >&2
    echo "in report only:" >&2
    LC_ALL=C comm -13 "$tmp" "$expf" >&2
    exit 1
  fi
fi
cat "$tmp"
