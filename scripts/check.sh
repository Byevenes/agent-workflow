#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
fail=0
bad() { echo "FAIL $*"; fail=1; }

n=$(grep -rlF 'Run inline when the Task tool is absent' --exclude-dir=.git --exclude-dir=.scratch --exclude-dir=retros --exclude=check.sh . | wc -l | tr -d ' ')
[ "$n" -eq 1 ] || bad "inline-trigger sentence must live only in skills/zstack/SKILL.md (found in $n files)"

for f in skills/zstack/SKILL.md agents/opencode/zstack.md; do
  grep -q -- '--force' "$f" || bad "$f: client rule about --force missing"
done

if grep -rnE 'SDD|sdd-|tech-lead|test-engineer' skills/zstack rules agents; then bad "zstack copies reference SDD, tech-lead or test-engineer"; fi

if grep -rnE '"subagent_type": *"(implementer|code-reviewer)"|`(implementer|code-reviewer|coordinator)`' skills/zstack rules agents README.md AGENTS.md docs/software-factory.md docs/workflow.md; then bad "old role names in live copies"; fi

for f in scripts/*.sh .githooks/*; do
  sh -n "$f" || bad "$f: syntax"
  if awk 'NR>1 && /^[[:space:]]*#/ && !/https?:\/\/|SPDX|[Ll]icense/' "$f" | grep -q .; then bad "$f: comment without issue/RFC link or license"; fi
done

if command -v shellcheck >/dev/null 2>&1; then shellcheck -e SC2016 scripts/*.sh .githooks/* || bad shellcheck; else bad "shellcheck missing (brew install shellcheck)"; fi

if [ "$(date +%Y%m%d)" -ge 20261201 ] && { [ -e skills/route-work ] || grep -q route-work scripts/link.sh; }; then bad "route-work alias expired 2026-12-01: delete skills/route-work and its link.sh lines"; fi

tmp=$(mktemp -d)
HOME=$tmp scripts/link.sh >/dev/null
for p in .cursor/skills/zstack .cursor/skills/zgrill .cursor/skills/zpr .cursor/rules/zstack.mdc .cursor/agents/zninja.md .config/opencode/skills/zstack .config/opencode/zstack.md .config/opencode/agents/zstack.md; do
  [ -L "$tmp/$p" ] && [ -e "$tmp/$p" ] || bad "link.sh smoke: $p not linked"
done
rm -rf "$tmp"

ra=$(mktemp -d)
mkdir -p "$ra/p/agent-transcripts"
printf '%s\n' 'zstack: small, full verifiable' '"name":"Write"' 'zninja launched: no (inline: Task tool absent)' > "$ra/p/agent-transcripts/ok.jsonl"
ROUTE_AUDIT_BASE=$ra scripts/route-audit.sh >/dev/null || bad "route-audit: fails on a clean fixture"
printf '%s\n' 'zstack: small, full verifiable' '"name":"Write"' > "$ra/p/agent-transcripts/noreason.jsonl"
if ROUTE_AUDIT_BASE=$ra scripts/route-audit.sh >/dev/null; then bad "route-audit: passes an inline edit without a reason"; fi
rm "$ra/p/agent-transcripts/noreason.jsonl"
printf '%s\n' 'zstack: medium, full verifiable' '"name":"Write"' 'zninja launched: no (inline: Task tool absent)' > "$ra/p/agent-transcripts/norev.jsonl"
if ROUTE_AUDIT_BASE=$ra scripts/route-audit.sh >/dev/null; then bad "route-audit: passes a medium edit without zsensei"; fi
rm "$ra/p/agent-transcripts/norev.jsonl"
printf '%s\n' '{"role":"assistant","message":{"content":[{"type":"text","text":"Clasificación **Medium** (zstack): dos piezas."}]}}' '{"type":"tool_use","name":"Write"}' '{"text":"zninja launched: no (inline: Task tool absent)"}' > "$ra/p/agent-transcripts/real.jsonl"
if ROUTE_AUDIT_BASE=$ra scripts/route-audit.sh >/dev/null; then bad "route-audit: misses a real-format Medium transcript without zsensei"; fi
rm -rf "$ra"

[ "$fail" -eq 0 ] && echo "check ok"
exit "$fail"
