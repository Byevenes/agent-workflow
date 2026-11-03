#!/bin/sh
set -eu
filter=${1:-}
days=${2:-7}
base="${ROUTE_AUDIT_BASE:-$HOME/.cursor/projects}"
files=$(find "$base" -path "*${filter}*" -path '*agent-transcripts*' -name '*.jsonl' -not -path '*/subagents/*' -mtime "-$days" 2>/dev/null || true)
total=0; rw=0; impl=0; pm=0; pa=0; why=0; nowhy=0; noedit=0; norev=0; nosize=0; legacy=0
canonre='(zstack|route-work): *[*]*(small|medium|large|critical)[*]*, *(full|partial) verifiable'
sizere='((zstack|route-work)[: (]+[*]*|size: *[*]*|clasific[a-z]* (como )?[*]*|clasificaci.n:? *[*]*|classif[a-z]* (as )?[*]*)(small|medium|large|critical)'
for f in $files; do
  total=$((total + 1))
  dir=${f%.jsonl}
  grep -q '"subagent_type":"poteto-agent"' "$f" && pa=$((pa + 1))
  grep -Eq 'zstack|route-work' "$f" || continue
  rw=$((rw + 1))
  if grep -rqs 'poteto-mode: loaded' "$f" "$dir/subagents" 2>/dev/null; then pm=$((pm + 1)); fi
  size=$(grep -oiE "$canonre" "$f" | head -1 | grep -oiE 'small|medium|large|critical' | head -1 | tr '[:upper:]' '[:lower:]' || true)
  if [ -z "$size" ]; then
    size=$(grep -oiE "$sizere" "$f" | head -1 | grep -oiE '(small|medium|large|critical)$' | tr '[:upper:]' '[:lower:]' || true)
    if [ -n "$size" ]; then legacy=$((legacy + 1)); else nosize=$((nosize + 1)); fi
  fi
  if grep -Eq '"name":"(StrReplace|Write|Edit|MultiEdit|EditNotebook|Delete)"' "$f"; then
    case $size in
      medium|large|critical) grep -q '"subagent_type":"zsensei"' "$f" || norev=$((norev + 1)) ;;
      *) ;;
    esac
  fi
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
echo "size undetected (no classification line): $nosize"
echo "size in a legacy format (not the canonical zstack line): $legacy"
if [ "$nowhy" -gt 0 ] || [ "$norev" -gt 0 ] || [ "$nosize" -gt 0 ]; then
  echo "route-audit: FAIL (inline edits without a reason, medium+ without zsensei, or size undetected)"; exit 1
fi
