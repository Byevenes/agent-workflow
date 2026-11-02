#!/bin/sh
set -eu
filter=${1:-}
days=${2:-7}
base="$HOME/.cursor/projects"
files=$(find "$base" -path "*${filter}*" -path '*agent-transcripts*' -name '*.jsonl' -not -path '*/subagents/*' -mtime "-$days" 2>/dev/null || true)
total=0; rw=0; impl=0; pm=0; pa=0
for f in $files; do
  total=$((total + 1))
  dir=${f%.jsonl}
  grep -Eq 'zstack|route-work' "$f" && rw=$((rw + 1))
  grep -Eq '"subagent_type":"(zninja|implementer)"' "$f" && impl=$((impl + 1))
  grep -q '"subagent_type":"poteto-agent"' "$f" && pa=$((pa + 1))
  if grep -rqs 'poteto-mode: loaded' "$f" "$dir/subagents" 2>/dev/null; then pm=$((pm + 1)); fi
done
echo "sessions (last ${days}d${filter:+, $filter}): $total"
echo "zstack or route-work invoked: $rw"
echo "zninja or implementer launched: $impl"
echo "poteto-mode loaded by implementer: $pm"
echo "poteto-agent delegates: $pa"
