#!/bin/sh
set -eu
filter=${1:-}
days=${2:-7}
base="${ROUTE_AUDIT_BASE:-$HOME/.cursor/projects}"
files=$(find "$base" -path "*${filter}*" -path '*agent-transcripts*' -name '*.jsonl' -not -path '*/subagents/*' -mtime "-$days" 2>/dev/null || true)
total=0; rw=0; impl=0; pm=0; pa=0; why=0; nowhy=0; noedit=0; norev=0
for f in $files; do
  total=$((total + 1))
  dir=${f%.jsonl}
  grep -q '"subagent_type":"poteto-agent"' "$f" && pa=$((pa + 1))
  grep -Eq 'zstack|route-work' "$f" || continue
  rw=$((rw + 1))
  if grep -rqs 'poteto-mode: loaded' "$f" "$dir/subagents" 2>/dev/null; then pm=$((pm + 1)); fi
  if grep -Eq '"name":"(StrReplace|Write|Edit|MultiEdit|EditNotebook|Delete)"' "$f" && grep -Eq '(zstack|route-work): (medium|large|critical)' "$f" && ! grep -q '"subagent_type":"zsensei"' "$f"; then norev=$((norev + 1)); fi
  if grep -Eq '"subagent_type":"(zninja|implementer)"' "$f"; then impl=$((impl + 1))
  elif ! grep -Eq '"name":"(StrReplace|Write|Edit|MultiEdit|EditNotebook|Delete)"' "$f"; then noedit=$((noedit + 1))
  elif grep -Eq 'launched: no \(inline: [^<]' "$f"; then why=$((why + 1))
  else nowhy=$((nowhy + 1)); fi
done
echo "sessions (last ${days}d${filter:+, $filter}): $total"
echo "zstack or route-work invoked: $rw"
echo "  zninja or implementer launched: $impl"
echo "  edited inline, reason stated: $why"
echo "  edited inline, no reason: $nowhy"
echo "  no edits: $noedit"
echo "poteto-mode loaded (zninja or inline): $pm"
echo "poteto-agent delegates: $pa"
echo "medium+ edited without zsensei: $norev"
if [ "$nowhy" -gt 0 ] || [ "$norev" -gt 0 ]; then
  echo "route-audit: FAIL (inline edits without a reason or medium+ without zsensei)"; exit 1
fi
