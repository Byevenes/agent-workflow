#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX
cd "$(dirname "$0")/.."
fail=0
bad() { echo "FAIL $*"; fail=1; }

n=$(grep -rlF 'Run inline when the Task tool is absent' --exclude-dir=.git --exclude-dir=.scratch --exclude-dir=retros --exclude=check.sh . | wc -l | tr -d ' ')
[ "$n" -eq 1 ] || bad "inline-trigger sentence must live only in skills/zstack/SKILL.md (found in $n files)"

for f in skills/zstack/SKILL.md agents/opencode/zstack.md; do
  grep -q -- '--force' "$f" || bad "$f: client rule about --force missing"
  grep -q 'Client slice commits' "$f" || bad "$f: client slice commit rule missing"
done

grep -q 'technology-agnostic' skills/zstack/SKILL.md || bad "zstack: client checks must be detected agnostically"
grep -q 'Never invent checks' skills/zstack/SKILL.md || bad "zstack: client rule must forbid invented checks"
grep -q 'Pre-push gate' skills/zstack/SKILL.md || bad "zstack: client rule must define the pre-push gate"
grep -q 'push_checks' docs/examples/clients.toml.example || bad "clients.toml.example: push_checks missing"
grep -q 'Recovery case' skills/zstack/SKILL.md || bad "zstack: client commit rule must define the mixed-slices recovery case"
grep -q 'scope changed' skills/zstack/SKILL.md || bad "zstack: client commit rule must stop on a scope change"
grep -q 'git add -A' skills/zstack/SKILL.md || bad "zstack: client commit rule must forbid git add -A"
grep -q 'never use `--no-verify`' skills/zstack/SKILL.md || bad "zstack: client commit rule must forbid --no-verify"

if grep -rnE 'SDD|sdd-|tech-lead|test-engineer' skills/zstack rules agents; then bad "zstack copies reference SDD, tech-lead or test-engineer"; fi

if grep -rnE '"subagent_type": *"(implementer|code-reviewer)"|`(implementer|code-reviewer|coordinator)`' skills/zstack rules agents README.md AGENTS.md docs/software-factory.md docs/workflow.md; then bad "old role names in live copies"; fi

for f in scripts/*.sh .githooks/* hooks/client-guard/*; do
  sh -n "$f" || bad "$f: syntax"
  if awk 'NR>1 && /^[[:space:]]*#/ && !/https?:\/\/|SPDX|[Ll]icense/' "$f" | grep -q .; then bad "$f: comment without issue/RFC link or license"; fi
done

if command -v shellcheck >/dev/null 2>&1; then shellcheck -e SC2016 scripts/*.sh .githooks/* hooks/client-guard/* || bad shellcheck; else bad "shellcheck missing (brew install shellcheck)"; fi

if [ "$(date +%Y%m%d)" -ge 20261201 ] && { [ -e skills/route-work ] || grep -q route-work scripts/link.sh; }; then bad "route-work alias expired 2026-12-01: delete skills/route-work and its link.sh lines"; fi

tmp=$(mktemp -d)
mkdir -p "$tmp/.cursor/skills/realdir" "$tmp/.config/opencode/skills"
ln -s "$tmp/nowhere" "$tmp/.cursor/skills/broken"
ln -s "$tmp/nowhere" "$tmp/.config/opencode/skills/broken"
HOME=$tmp scripts/link.sh >/dev/null
if [ -L "$tmp/.cursor/skills/broken" ] || [ -L "$tmp/.config/opencode/skills/broken" ]; then bad "link.sh: keeps a broken skill symlink"; fi
[ -d "$tmp/.cursor/skills/realdir" ] || bad "link.sh: removed a real skill folder"
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
(cd "$cg/r" && HOME=$cg CLIENTS_ROOT='' "$OLDPWD/hooks/client-guard/pre-push" origin https://github.com/Byevenes/x.git >/dev/null) || bad "client-guard: blocks a personal GitHub push"
if (cd "$cg/r" && HOME=$cg CLIENTS_ROOT='' "$OLDPWD/hooks/client-guard/pre-push" origin git@bitbucket.org:client/x.git >/dev/null); then bad "client-guard: allows a bitbucket push"; fi
mkdir -p "$cg/Clients/c"
git init -q "$cg/Clients/c/r"
if (cd "$cg/Clients/c/r" && HOME=$cg CLIENTS_ROOT='' "$OLDPWD/hooks/client-guard/pre-push" origin https://github.com/c/x.git >/dev/null); then bad "client-guard: allows a push under the clients root"; fi
(cd "$cg/Clients/c/r" && HOME=$cg CLIENTS_ROOT='' CLIENT_PUSH_OK=brayan "$OLDPWD/hooks/client-guard/pre-push" origin x >/dev/null) || bad "client-guard: ignores CLIENT_PUSH_OK=brayan"
(cd "$cg/r" && HOME=$cg CLIENTS_ROOT='' "$OLDPWD/hooks/client-guard/pre-commit" >/dev/null) || bad "client-guard pre-commit: blocks a personal repo"
if (cd "$cg/Clients/c/r" && HOME=$cg CLIENTS_ROOT='' "$OLDPWD/hooks/client-guard/pre-commit" >/dev/null); then bad "client-guard pre-commit: allows a commit under the clients root"; fi
git -C "$cg/r" remote add origin git@gitlab.com:client/x.git
if (cd "$cg/r" && HOME=$cg CLIENTS_ROOT='' "$OLDPWD/hooks/client-guard/pre-commit" >/dev/null); then bad "client-guard pre-commit: allows a commit with a gitlab origin"; fi
(cd "$cg/Clients/c/r" && HOME=$cg CLIENTS_ROOT='' CLIENT_PUSH_OK=brayan "$OLDPWD/hooks/client-guard/pre-commit" >/dev/null) || bad "client-guard pre-commit: ignores CLIENT_PUSH_OK=brayan"
rm -rf "$cg"

cr=$(mktemp -d)
mk() { git init -q "$cr/$1"; }
mk a/back/repos/r1
mk a/back/repos/r2
mk b/front/repos/h
git -C "$cr/b/front/repos/h" config core.hooksPath .husky
git -C "$cr/a/back/repos/r1" -c user.name=t -c user.email=t@t commit -q --allow-empty -m x
git -C "$cr/a/back/repos/r1" worktree add -q "$cr/a/back/worktrees/r1/w" -b w 2>/dev/null
for r in a/back/repos/r1 a/back/repos/r2; do printf '#!/bin/sh\n# client-guard\n' > "$cr/$r/.git/hooks/pre-push"; done
out=$(CLIENTS_ROOT=$cr ZSTACK_CLIENTS_TOML=/nonexistent/zstack-clients.toml sh scripts/setup-check.sh 2>/dev/null | grep "client-guard: pre-push")
[ "$out" = "ok client-guard: pre-push in 2/3 client repos, skipped (husky) 1" ] || bad "setup-check client-guard count: $out"
rm -rf "$cr"

ci=$(mktemp -d)
git init -q "$ci/acme/back/repos/c"
git -C "$ci/acme/back/repos/c" config user.email dev@other.example
git init -q "$ci/other/back/repos/o"
git -C "$ci/other/back/repos/o" config user.email dev@other.example
git init -q "$ci/plain/back/repos/u"
git -C "$ci/plain/back/repos/u" config user.email dev@other.example
printf '.scratch/\n' >> "$ci/other/back/repos/o/.git/info/exclude"
toml=$(mktemp)
cat > "$toml" <<EOF
clients_root = "/no/such/clients-root"

[clients.acme]
root = "$ci/acme"
git_email = "dev@acme.example"
git_email_domains = ["@acme.example"]

[clients.other]
root = "$ci/other"
git_email_domains = ["@acme.example"]
EOF
out=$(CLIENTS_ROOT=$ci ZSTACK_CLIENTS_TOML=$toml sh scripts/setup-check.sh 2>/dev/null || true)
echo "$out" | grep -q "^fail client identity: $ci/acme/back/repos/c uses 'dev@other.example', expected the client map git_email" || bad "setup-check: passes a strict client repo with the wrong email"
echo "$out" | grep -q "^warn client identity: $ci/other/back/repos/o uses 'dev@other.example', expected a client map git_email_domains suffix" || bad "setup-check: does not warn on a domains client with the wrong email"
echo "$out" | grep -q "^fail client identity: $ci/other" && bad "setup-check: fails a domains-only client on identity"
echo "$out" | grep -q "client identity: $ci/plain" && bad "setup-check: identity line for an unlisted repo"
echo "$out" | grep -q "scratch-exclude: .scratch/ in info/exclude in 1/3" || bad "setup-check: scratch-exclude count wrong"
cat > "$toml" <<EOF
clients_root = "$ci"

[clients.acme]
root = "$ci/acme"
git_email = "dev@acme.example"

[clients.other]
root = "$ci/other"
git_email_domains = ["@acme.example"]
EOF
out=$(CLIENTS_ROOT='' ZSTACK_CLIENTS_TOML=$toml sh scripts/setup-check.sh 2>/dev/null || true)
echo "$out" | grep -q "^fail client identity: $ci/acme/back/repos/c uses 'dev@other.example', expected the client map git_email" || bad "setup-check: ignores clients_root when CLIENTS_ROOT is unset"
git -C "$ci/acme/back/repos/c" config user.email dev@acme.example
CLIENTS_ROOT=$ci ZSTACK_CLIENTS_TOML=$toml sh scripts/setup-check.sh 2>/dev/null | grep -q "^fail client identity: $ci/acme" && bad "setup-check: fails a strict client repo with the mapped email"
nest=$(mktemp -d)
git init -q "$nest/acme/inner"
git -C "$nest/acme/inner" config user.email dev@acme.example
ntoml=$(mktemp)
cat > "$ntoml" <<EOF
[clients.wide]
root = "$nest/acme"
git_email = "dev@other.example"

[clients.inner]
root = "$nest/acme/inner"
git_email = "dev@acme.example"
EOF
CLIENTS_ROOT=$nest ZSTACK_CLIENTS_TOML=$ntoml sh scripts/setup-check.sh 2>/dev/null | grep -q '^fail client identity:' && bad "setup-check: longest client root prefix lost"
oh=$(mktemp -d)
mkdir -p "$oh/.config/opencode/agents"
printf -- '---\nmodel: opencode/big-pickle\n---\n' > "$oh/.config/opencode/agents/zninja.md"
HOME=$oh CLIENTS_ROOT=$ci ZSTACK_CLIENTS_TOML=/nonexistent/zstack-clients.toml sh scripts/setup-check.sh 2>/dev/null | grep -q '^fail opencode zninja' || bad "setup-check: passes an opencode/* model on zninja"
rm -rf "$ci" "$oh" "$nest"
rm -f "$toml" "$ntoml"

for f in scripts/check.sh scripts/link.sh scripts/setup-check.sh; do
  sed -n 3p "$f" | grep -qx "$(printf '%s' 'unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX')" || bad "$f: line 3 must unset the GIT_* hook env (GIT_DIR leak sets core.bare=true on the parent repo)"
done
if [ -z "${CHECK_NESTED:-}" ]; then
  hk=$(mktemp -d)
  git init -q "$hk/p"
  git -C "$hk/p" -c user.name=t -c user.email=t@t commit -q --allow-empty -m x
  git -C "$hk/p" remote add origin https://example.invalid/p.git
  git -C "$hk/p" worktree add -q "$hk/w" -b w 2>/dev/null
  before=$(git -C "$hk/p" config --local --list | sort)
  GIT_DIR="$hk/p/.git/worktrees/w" GIT_INDEX_FILE="$hk/p/.git/worktrees/w/index" CHECK_NESTED=1 sh scripts/check.sh >/dev/null 2>&1 || bad "check.sh fails when run with a hook's GIT_DIR"
  after=$(git -C "$hk/p" config --local --list | sort)
  [ "$before" = "$after" ] || bad "check.sh under a hook's GIT_DIR changed the parent repo config: $(printf '%s\n' "$after" | grep -vxF "$before" | tr '\n' ' ')"
  rm -rf "$hk"
fi

[ "$fail" -eq 0 ] && echo "check ok"
exit "$fail"
