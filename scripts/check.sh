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

for f in scripts/*.sh .githooks/* hooks/client-guard/*; do
  sh -n "$f" || bad "$f: syntax"
  if awk 'NR>1 && /^[[:space:]]*#/ && !/https?:\/\/|SPDX|[Ll]icense/' "$f" | grep -q .; then bad "$f: comment without issue/RFC link or license"; fi
done

if command -v shellcheck >/dev/null 2>&1; then shellcheck -e SC2016 scripts/*.sh .githooks/* hooks/client-guard/* || bad shellcheck; else bad "shellcheck missing (brew install shellcheck)"; fi

if [ "$(date +%Y%m%d)" -ge 20261201 ] && { [ -e skills/route-work ] || grep -q route-work scripts/link.sh; }; then bad "route-work alias expired 2026-12-01: delete skills/route-work and its link.sh lines"; fi

tmp=$(mktemp -d)
HOME=$tmp scripts/link.sh >/dev/null
for p in .cursor/skills/zstack .cursor/skills/zgrill .cursor/skills/zpr .cursor/rules/zstack.mdc .cursor/agents/zninja.md .config/opencode/skills/zstack .config/opencode/zstack.md .config/opencode/agents/zstack.md; do
  if [ ! -L "$tmp/$p" ] || [ ! -e "$tmp/$p" ]; then bad "link.sh smoke: $p not linked"; fi
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
rm "$ra/p/agent-transcripts/real.jsonl"
printf '%s\n' 'using zstack skill' 'zninja launched: no (inline: Task tool absent)' > "$ra/p/agent-transcripts/nosize.jsonl"
if ROUTE_AUDIT_BASE=$ra scripts/route-audit.sh >/dev/null; then bad "route-audit: passes a zstack session with no classification line"; fi
rm "$ra/p/agent-transcripts/nosize.jsonl"
printf '%s\n' 'zstack: Medium, full verifiable — x' '"name":"Write"' '"subagent_type":"zsensei"' 'zninja launched: no (inline: Task tool absent)' > "$ra/p/agent-transcripts/mupin.jsonl"
if ROUTE_AUDIT_BASE=$ra scripts/route-audit.sh >/dev/null; then bad "route-audit: passes a Medium inline edit without zninja"; fi
printf '%s\n' 'zstack: Medium, full verifiable — x' '"name":"Write"' '"subagent_type":"zsensei"' '"subagent_type":"zninja"' > "$ra/p/agent-transcripts/mupin.jsonl"
ROUTE_AUDIT_BASE=$ra scripts/route-audit.sh >/dev/null || bad "route-audit: fails a Medium session with zninja and zsensei"
rm "$ra/p/agent-transcripts/mupin.jsonl"
printf '%s\n' '{"text":"zstack: **Large**, partial verifiable — migración"}' > "$ra/p/agent-transcripts/canon.jsonl"
ROUTE_AUDIT_BASE=$ra scripts/route-audit.sh | grep -q 'size undetected (no classification line): 0' || bad "route-audit: misses a canonical line with bold size"
rm -rf "$ra"

cg=$(mktemp -d)
git init -q "$cg/r"
(cd "$cg/r" && HOME=$cg "$OLDPWD/hooks/client-guard/pre-push" origin https://github.com/Byevenes/x.git >/dev/null) || bad "client-guard: blocks a personal GitHub push"
if (cd "$cg/r" && HOME=$cg "$OLDPWD/hooks/client-guard/pre-push" origin git@bitbucket.org:client/x.git >/dev/null); then bad "client-guard: allows a bitbucket push"; fi
mkdir -p "$cg/Sites/tinet/Clients/c"
git init -q "$cg/Sites/tinet/Clients/c/r"
if (cd "$cg/Sites/tinet/Clients/c/r" && HOME=$cg "$OLDPWD/hooks/client-guard/pre-push" origin https://github.com/c/x.git >/dev/null); then bad "client-guard: allows a push under Sites/tinet/Clients"; fi
(cd "$cg/Sites/tinet/Clients/c/r" && HOME=$cg CLIENT_PUSH_OK=brayan "$OLDPWD/hooks/client-guard/pre-push" origin x >/dev/null) || bad "client-guard: ignores CLIENT_PUSH_OK=brayan"
rm -rf "$cg"

unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE GIT_OBJECT_DIRECTORY
cr=$(mktemp -d)
mk() { git init -q "$cr/$1"; }
mk a/back/repos/r1
mk a/back/repos/r2
mk b/front/repos/h
git -C "$cr/b/front/repos/h" config core.hooksPath .husky
git -C "$cr/a/back/repos/r1" -c user.name=t -c user.email=t@t commit -q --allow-empty -m x
git -C "$cr/a/back/repos/r1" worktree add -q "$cr/a/back/worktrees/r1/w" -b w 2>/dev/null
for r in a/back/repos/r1 a/back/repos/r2; do printf '#!/bin/sh\n# client-guard\n' > "$cr/$r/.git/hooks/pre-push"; done
out=$(CLIENTS_ROOT=$cr sh scripts/setup-check.sh 2>/dev/null | grep client-guard)
[ "$out" = "ok client-guard: pre-push in 2/3 client repos, skipped (husky) 1" ] || bad "setup-check client-guard count: $out"
rm -rf "$cr"

[ "$fail" -eq 0 ] && echo "check ok"
exit "$fail"
