#!/bin/sh
set -eu
filter=${1:-}
days=${2:-7}
base="${ROUTE_AUDIT_BASE:-$HOME/.cursor/projects}"
files=$(find "$base" -path "*${filter}*" -path '*agent-transcripts*' -name '*.jsonl' -not -path '*/subagents/*' -mtime "-$days" 2>/dev/null || true)
total=0; rw=0; impl=0; pm=0; pa=0; why=0; nowhy=0; noedit=0; norev=0; mupinline=0; nosize=0; legacy=0
dlg=0; dbig=0; drev=0; ofix=0; report=0
canonre='(zstack|route-work): *[*]*(small|medium|large|critical)[*]*, *(full|partial) verifiable'
sizere='((zstack|route-work)[: (]+[*]*|size: *[*]*|clasific[a-z]* (como )?[*]*|clasificaci.n:? *[*]*|classif[a-z]* (as )?[*]*)(small|medium|large|critical)'
toolre='"name":"(StrReplace|Write|Edit|MultiEdit|EditNotebook|Delete)"'
pathre='"name":"(StrReplace|Write|Edit|MultiEdit|EditNotebook|Delete)","input":\{"path":"[^"]*"'
testre='(/tests?/|[.]tests?/|tests?[.][a-z]+"$|[._-](test|tests|spec)[.][a-z]+"$)'
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
  role=$(grep -oE 'zstack delegated: (impl|fix|review)' "$f" | head -1 | sed 's/.*: //' || true)
  [ -n "$role" ] && dlg=$((dlg + 1))
  [ "$role" = review ] && case $size in large|critical) drev=$((drev + 1)) ;; esac
  alledits=$(grep -oE "$toolre" "$f" | wc -l | tr -d ' ')
  scratchedits=$(grep -oE "$pathre" "$f" | grep -c '/[.]scratch/' || true)
  codeedits=$((alledits - scratchedits))
  if [ "$alledits" -gt 0 ] && [ "$codeedits" -eq 0 ]; then report=$((report + 1)); fi
  nontest=$((codeedits - $(grep -oE "$pathre" "$f" | grep -v '/[.]scratch/' | grep -ciE "$testre" || true)))
  zn=0
  grep -Eq '"subagent_type":"(zninja|implementer)"' "$f" && zn=1
  case $role in impl|fix) zn=1 ;; esac
  if [ "$codeedits" -gt 0 ]; then
    case $size in
      medium|large|critical)
        if [ "$zn" -eq 0 ]; then
          if [ "$nontest" -eq 0 ] && grep -Eq 'launched: no \(orchestrator-fix: [^<)]' "$f"; then ofix=$((ofix + 1))
          else mupinline=$((mupinline + 1)); fi
        fi ;;
      *) ;;
    esac
    case $size in
      large|critical)
        if ! grep -q '"subagent_type":"zsensei"' "$f"; then
          case $role in impl|fix) dbig=$((dbig + 1)) ;; *) norev=$((norev + 1)) ;; esac
        fi ;;
      *) ;;
    esac
  fi
  if [ "$zn" -eq 1 ]; then impl=$((impl + 1))
  elif [ "$codeedits" -eq 0 ]; then noedit=$((noedit + 1))
  elif grep -Eq 'launched: no \((inline|orchestrator-fix): [^<]' "$f"; then why=$((why + 1))
  else nowhy=$((nowhy + 1)); fi
done
if [ "$dbig" -gt 0 ] && [ "$drev" -eq 0 ]; then norev=$((norev + dbig)); fi
echo "sessions (last ${days}d${filter:+, $filter}): $total"
echo "zstack or route-work invoked: $rw"
echo "  zninja or implementer launched: $impl"
echo "  edited inline, reason stated: $why"
echo "  edited inline, no reason: $nowhy"
echo "  no edits: $noedit"
echo "    of which only report files under .scratch/: $report"
echo "delegated runs (zstack delegated: impl|fix|review): $dlg"
echo "  large or critical delegated reviews: $drev"
echo "orchestrator test fixes with a stated reason: $ofix"
echo "poteto-mode loaded (zninja or inline): $pm"
echo "poteto-agent delegates: $pa"
echo "large or critical edited without zsensei: $norev"
echo "medium+ inline (edited without zninja): $mupinline"
echo "size undetected (no classification line): $nosize"
echo "size in a legacy format (not the canonical zstack line): $legacy"
if [ "$nowhy" -gt 0 ] || [ "$norev" -gt 0 ] || [ "$mupinline" -gt 0 ] || [ "$nosize" -gt 0 ]; then
  echo "route-audit: FAIL (inline edits without a reason, large or critical without zsensei, medium+ inline, or size undetected)"; exit 1
fi
