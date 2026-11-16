#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
RULES=$ROOT/docs/delegated-run-rules.md

usage() {
  echo "usage: scripts/cursor-delegate.sh --workspace <dir> --prompt <file> --out <file> [--model <slug>] [--approval sandbox|auto-review] [--idle <seconds>] [--max <seconds>]" >&2
  exit 2
}

number() {
  case $1 in
    ''|*[!0-9]*) usage ;;
  esac
}

ws=''
prompt=''
out=''
model=${DELEGATE_MODEL:-grok-4.7-high}
approval=sandbox
idle=${DELEGATE_IDLE:-900}
max=${DELEGATE_MAX:-0}
bin=${AGENT_BIN:-agent}

while [ $# -gt 0 ]; do
  [ $# -ge 2 ] || usage
  case $1 in
    --workspace) ws=$2 ;;
    --prompt) prompt=$2 ;;
    --out) out=$2 ;;
    --model) model=$2 ;;
    --approval) approval=$2 ;;
    --idle) idle=$2 ;;
    --max) max=$2 ;;
    *) usage ;;
  esac
  shift 2
done

[ -n "$ws" ] && [ -n "$prompt" ] && [ -n "$out" ] || usage
[ -d "$ws" ] || { echo "cursor-delegate: workspace not found: $ws" >&2; exit 2; }
[ -f "$prompt" ] || { echo "cursor-delegate: prompt not found: $prompt" >&2; exit 2; }
[ -f "$RULES" ] || { echo "cursor-delegate: rules missing: $RULES" >&2; exit 2; }
number "$idle"
number "$max"
case $model in
  *-fast|*-fast\[*) [ "${DELEGATE_ALLOW_FAST:-}" = 1 ] || { echo "cursor-delegate: -fast models need an explicit reason; pass another --model or set DELEGATE_ALLOW_FAST=1" >&2; exit 2; } ;;
esac

text=$(cat "$RULES"; printf '\n---\n\n'; cat "$prompt")

set -- -p --trust
case $approval in
  sandbox) set -- "$@" --sandbox enabled ;;
  auto-review) set -- "$@" --auto-review ;;
  *) usage ;;
esac
set -- "$@" --workspace "$ws" --model "$model" --output-format stream-json "$text"

meta=$out.meta
start=$(date +%Y-%m-%dT%H:%M:%S%z)
: >"$out"
printf 'start=%s\nmodel=%s\napproval=%s\nidle=%s\nmax=%s\n' "$start" "$model" "$approval" "$idle" "$max" >"$meta"

set -m
"$bin" "$@" >"$out" 2>"$out.err" &
pid=$!
set +m

last=-1
quiet=0
elapsed=0
why=''
while kill -0 "$pid" 2>/dev/null; do
  sleep 1
  elapsed=$((elapsed + 1))
  size=$(wc -c <"$out" | tr -d ' ')
  if [ "$size" != "$last" ]; then
    last=$size
    quiet=0
  else
    quiet=$((quiet + 1))
  fi
  if [ "$idle" -gt 0 ] && [ "$quiet" -ge "$idle" ]; then why="idle ${quiet}s"; break; fi
  if [ "$max" -gt 0 ] && [ "$elapsed" -ge "$max" ]; then why="max ${elapsed}s"; break; fi
done

if [ -n "$why" ]; then
  kill -TERM -- "-$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null || true
  sleep 2
  kill -KILL -- "-$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  printf 'exit=killed(%s)\nend=%s\n' "$why" "$(date +%Y-%m-%dT%H:%M:%S%z)" >>"$meta"
  echo "cursor-delegate: killed after $why without output; run the stuck step outside the sandbox" >&2
  exit 124
fi

rc=0
wait "$pid" || rc=$?
printf 'exit=%s\nend=%s\n' "$rc" "$(date +%Y-%m-%dT%H:%M:%S%z)" >>"$meta"
if command -v jq >/dev/null 2>&1; then
  jq -r 'select(.type == "result") | .result // empty' "$out" >"$out.txt" 2>/dev/null || true
fi
exit "$rc"
