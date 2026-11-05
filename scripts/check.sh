#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX
if [ -n "${GIT_CONFIG_COUNT:-}" ]; then
  _i=0
  while [ "$_i" -lt "$GIT_CONFIG_COUNT" ]; do
    unset "GIT_CONFIG_KEY_${_i}" "GIT_CONFIG_VALUE_${_i}"
    _i=$((_i + 1))
  done
fi
unset GIT_CONFIG_COUNT GIT_CONFIG_PARAMETERS
cd "$(dirname "$0")/.."
fail=0
bad() { echo "FAIL $*"; fail=1; }

check_project_agents() {
  for agent in zigl zninja zsensei; do
    p=".cursor/agents/$agent.md"
    if [ ! -L "$p" ]; then
      bad "project agent $p is not a symlink"
      continue
    fi
    if [ ! -e "$p" ]; then
      bad "project agent $p does not resolve"
      continue
    fi
    target=$(readlink "$p")
    if [ "$target" != "../../agents/$agent.md" ]; then
      bad "project agent $p target is $target"
    fi
  done
}

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
grep -q '### Slice loop' skills/zstack/SKILL.md || bad "zstack: slice loop missing"
grep -q 'A recovery plan does not replace that new session' skills/zstack/SKILL.md || bad "zstack: recovery must not replace a new session per slice"
grep -q 'The next ticket is not started here' skills/zstack/SKILL.md || bad "zstack: slice close must require a clean session"
grep -q 'scripts/check-commit-order.sh' skills/zstack/SKILL.md || bad "zstack: commit-order gate missing"
grep -q 'scripts/check-commit-order.sh' docs/scripts.md || bad "scripts.md: commit-order gate missing"
grep -q 'explicit yes' agents/zninja.md || bad "zninja: out-of-scope bug must stop for an explicit yes"
grep -q 'Do not mix the bugfix and the feature in one commit' agents/zninja.md || bad "zninja: bugfix and feature may share a commit"
grep -q 'the `fix:` commit is an ancestor of the feature commit' agents/zninja.md || bad "zninja: review checklist missing"
fixline=$(grep -n 'fix: keep the empty input on the existing path' agents/zninja.md | head -1 | cut -d: -f1)
featline=$(grep -n "feat: add the ticket's slice" agents/zninja.md | head -1 | cut -d: -f1)
if [ -z "$fixline" ] || [ -z "$featline" ] || [ "$fixline" -ge "$featline" ]; then bad "zninja: fix: example is not before the feature example"; fi
grep -q 'that `fix:` commit is an ancestor of the feature commit' agents/zsensei.md || bad "zsensei: out-of-scope history checklist missing"
zn_front=$(awk 'BEGIN{n=0} /^---$/{n++; if (n==2) exit; next} n==1 {print}' agents/zninja.md)
if printf '%s\n' "$zn_front" | grep -q '^model:'; then bad "zninja: model must stay unset so the subagent inherits"; fi
if printf '%s\n' "$zn_front" | grep -q -- '-fast'; then bad "zninja: must not set a -fast model"; fi
zs_front=$(awk 'BEGIN{n=0} /^---$/{n++; if (n==2) exit; next} n==1 {print}' agents/zsensei.md)
if ! printf '%s\n' "$zs_front" | grep -qx 'model: claude-opus-5-5-medium'; then bad "zsensei: model must be claude-opus-5-5-medium"; fi
if ! printf '%s\n' "$zs_front" | grep -qx 'readonly: true'; then bad "zsensei: readonly must be true"; fi
grep -q 'issue #58' skills/zstack/SKILL.md || bad "zstack: inline fallback must cite issue #58"
grep -qF '.cursor/agents/' skills/zstack/SKILL.md || bad "zstack: inline fallback must name .cursor/agents/"
check_project_agents
grep -q 'scope changed' skills/zstack/SKILL.md || bad "zstack: client commit rule must stop on a scope change"
grep -q 'git add -A' skills/zstack/SKILL.md || bad "zstack: client commit rule must forbid git add -A"
grep -q 'never use `--no-verify`' skills/zstack/SKILL.md || bad "zstack: client commit rule must forbid --no-verify"

zs=skills/zstack/SKILL.md
grep -qF 'tickets = ceil(tokens_estimados * holgura / 150_000)' "$zs" || bad "zstack: token ticket formula missing"
grep -qF 'Medium whose estimate is about 150k tokens promotes to Large' "$zs" || bad "zstack: Medium promote to Large missing"
grep -qF 'Critical keeps the security path even when the ticket count is 1' "$zs" || bad "zstack: Critical security path for one ticket missing"
cal='.scratch/<slug>/calibracion.md'
grep -qF "$cal" "$zs" || bad "zstack: calibration log path missing"
grep -qF "$cal" skills/zretro/SKILL.md || bad "zretro: calibration log path missing"
mm=docs/model-matrix.md
grep -qF 'claude-opus-5-5-medium' "$mm" || bad "model-matrix: Opus slug missing"
grep -qF 'The review role is Claude Opus fixed' "$mm" || bad "model-matrix: Opus pin missing"
grep -qF 'no quota fallback that downgrades judgment' "$mm" || bad "model-matrix: review downgrade missing"
grep -qF 'inherit-parent' "$mm" || bad "model-matrix: quota fallback missing"
grep -qF 'docs/model-matrix.md' "$zs" || bad "zstack: model matrix pointer missing"
grep -qF '## Modelos' "$zs" || bad "zstack: Large close model table missing"
grep -qF 'docs/model-matrix.md' skills/zretro/SKILL.md || bad "zretro: model matrix pointer missing"
grep -qF '## Modelos' skills/zretro/SKILL.md || bad "zretro: Large close model table missing"
grep -qF 'fallback = []' docs/examples/model-matrix.toml || bad "model-matrix.toml: review fallback is not empty"
grep -qF 'claude-opus-5-5-medium' docs/examples/model-matrix.toml || bad "model-matrix.toml: Opus slug missing"
grep -qF 'grok-4.7-medium' docs/examples/model-matrix.toml || bad "model-matrix.toml: implement slug missing"
ex=docs/examples/calibracion-large.md
grep -qF '## Modelos' "$ex" || bad "calibracion-large: Modelos missing"
grep -qF '| zsensei | review | claude-opus-5-5-medium | claude-opus-5-5-medium | no |' "$ex" || bad "calibracion-large: review row drifted"
grep -qF '| zninja | implement | grok-4.7-medium | grok-4.7-medium | no |' "$ex" || bad "calibracion-large: implement row drifted"
if [ -e rules/pstack-models.mdc ] || [ -e .cursor/rules/pstack-models.mdc ]; then bad "model-matrix: pstack-models.mdc must stay outside this repo"; fi

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
check_project_agents
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
echo "$out" | grep -q "local-exclude: .scratch/ and .atl/ in info/exclude in 3/3" || bad "setup-check: local-exclude count wrong"
[ "$(grep -cxF '.scratch/' "$ci/other/back/repos/o/.git/info/exclude")" -eq 1 ] || bad "setup-check: duplicated a pre-existing .scratch/ line"
grep -qxF '.atl/' "$ci/other/back/repos/o/.git/info/exclude" || bad "setup-check: did not append .atl/ next to an existing .scratch/ line"
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

lx=$(mktemp -d)
git init -q "$lx/acme/svc"
printf '*.log' > "$lx/acme/svc/.git/info/exclude"
git init -q "$lx/acme/fresh"
rm -f "$lx/acme/fresh/.git/info/exclude"
out=$(CLIENTS_ROOT=$lx ZSTACK_CLIENTS_TOML=/nonexistent/zstack-clients.toml sh scripts/setup-check.sh 2>/dev/null || true)
echo "$out" | grep -q "local-exclude: .scratch/ and .atl/ in info/exclude in 2/2" || bad "setup-check: local-exclude fixture count: $out"
xf=$lx/acme/svc/.git/info/exclude
grep -qxF '*.log' "$xf" || bad "setup-check: dropped an unrelated exclude line"
grep -qxF '.scratch/' "$xf" || bad "setup-check: .scratch/ missing from info/exclude"
grep -qxF '.atl/' "$xf" || bad "setup-check: .atl/ missing from info/exclude"
[ "$(grep -cxF '.scratch/' "$xf")" -eq 1 ] || bad "setup-check: duplicated .scratch/"
[ "$(grep -cxF '.atl/' "$xf")" -eq 1 ] || bad "setup-check: duplicated .atl/"
ff=$lx/acme/fresh/.git/info/exclude
[ -f "$ff" ] || bad "setup-check: did not create info/exclude"
grep -qxF '.scratch/' "$ff" || bad "setup-check: created exclude without .scratch/"
grep -qxF '.atl/' "$ff" || bad "setup-check: created exclude without .atl/"
mkdir -p "$lx/acme/svc/.atl" "$lx/acme/svc/.scratch"
: > "$lx/acme/svc/.atl/foo"
: > "$lx/acme/svc/.scratch/x"
git -C "$lx/acme/svc" check-ignore -q -- .atl/foo || bad "setup-check: .atl/foo is not ignored"
git -C "$lx/acme/svc" check-ignore -q -- .scratch/x || bad "setup-check: .scratch/x is not ignored"
[ ! -e "$lx/acme/svc/.gitignore" ] || bad "setup-check: created .gitignore"
if git -C "$lx/acme/svc" status --porcelain | grep -q .; then bad "setup-check: client worktree is not clean"; fi
before=$(cksum "$xf" | awk '{print $1}')
CLIENTS_ROOT=$lx ZSTACK_CLIENTS_TOML=/nonexistent/zstack-clients.toml sh scripts/setup-check.sh >/dev/null 2>&1 || true
after=$(cksum "$xf" | awk '{print $1}')
[ "$before" = "$after" ] || bad "setup-check: second run changed info/exclude"
rm -rf "$lx"

clean=docs/examples/delivery-note-fixtures/clean.md
dirty=docs/examples/delivery-note-fixtures/dirty.md
tmpl=docs/examples/nota-de-entrega.md
for s in '## Qué cambió' '## Cómo verificar' '## Riesgos o confirmaciones pendientes'; do
  grep -qF -- "$s" "$clean" || bad "delivery-note: clean fixture missing $s"
  grep -qF -- "$s" "$tmpl" || bad "delivery-note: template missing $s"
done
sh scripts/check-delivery-note.sh "$clean" >/dev/null || bad "delivery-note: clean fixture failed"
if sh scripts/check-delivery-note.sh "$dirty" >/dev/null 2>&1; then bad "delivery-note: dirty fixture passed"; fi
if sh scripts/check-delivery-note.sh "$tmpl" >/dev/null 2>&1; then bad "delivery-note: template still sendable"; fi

rp_root=docs/examples/repo-path-fixtures/root
rp_clean=docs/examples/repo-path-fixtures/clean.md
rp_dirty=docs/examples/repo-path-fixtures/dirty.md
rp_tilde=$(printf '\176/work/src/Foo.cs')
sh scripts/check-repo-paths.sh "$rp_clean" "$rp_root" >/dev/null || bad "repo-paths: clean fixture failed"
rp_out=$(sh scripts/check-repo-paths.sh "$rp_dirty" "$rp_root" 2>&1 || true)
if sh scripts/check-repo-paths.sh "$rp_dirty" "$rp_root" >/dev/null 2>&1; then bad "repo-paths: dirty fixture passed"; fi
rp_has() {
  printf '%s\n' "$rp_out" | grep -qF -- "$1: $2" || bad "repo-paths: dirty fixture did not report $1: $2"
}
rp_has "does not exist from the repo root" "OnlyName.cs"
rp_has "does not exist from the repo root" "src/Missing.cs"
rp_has "absolute path" "/opt/src/Foo.cs"
rp_has "absolute path" "/Users/someone/src/Foo.cs"
rp_has "absolute path" "$rp_tilde"
rp_has "absolute path" "C:/src/Foo.cs"
rp_has "not a repo-root path" "./src/Foo/Bar.cs"
rp_has "not a repo-root path" "src/../src/Foo/Bar.cs"
rp_has "not a repo-root path" 'src\Foo\Bar.cs'
if sh scripts/check-repo-paths.sh >/dev/null 2>&1; then bad "repo-paths: usage without args passed"; fi

rp_anchors=docs/examples/repo-path-fixtures/anchors.md
rp_anchors_dirty=docs/examples/repo-path-fixtures/anchors-dirty.md
rp_anch_out=$(sh scripts/check-repo-paths.sh "$rp_anchors" "$rp_root" 2>&1) || bad "repo-paths: anchor fixture failed: $rp_anch_out"
rp_anch_status=0
rp_anch_out=$(sh scripts/check-repo-paths.sh "$rp_anchors_dirty" "$rp_root" 2>&1) || rp_anch_status=$?
[ "$rp_anch_status" -ne 0 ] || bad "repo-paths: anchor dirty fixture passed"
rp_anch_has() {
  printf '%s\n' "$rp_anch_out" | grep -qF -- "$1" || bad "repo-paths: anchor dirty fixture did not report $1"
}
rp_anch_has "does not exist from the repo root: src/Missing.cs ("
rp_anch_has "does not exist from the repo root: src/LinkMissing.cs ("
rp_anch_lacks() {
  if printf '%s\n' "$rp_anch_out" | grep -qF -- "$1"; then bad "repo-paths: anchor dirty fixture reported $1"; fi
}
rp_anch_lacks "src/**/*.cs"
rp_anch_lacks "https://"
rp_anch_lacks "mailto:"
rp_anch_lacks "#section"
rp_anch_lacks "src/Missing.cs#"
rp_anch_lacks "src/LinkMissing.cs:"

lesson=docs/examples/kdb-lesson-timezone.md
[ -f "$lesson" ] || bad "timezone lesson: missing"
grep -q 'como UTC' "$lesson" || bad "timezone lesson: missing UTC default"
grep -q 'Normaliza' "$lesson" || bad "timezone lesson: missing normalize-before-compare"
grep -q 'TZ' "$lesson" || bad "timezone lesson: missing TZ"

for f in scripts/check.sh scripts/link.sh scripts/setup-check.sh scripts/check-delivery-note.sh scripts/check-repo-paths.sh scripts/check-commit-order.sh; do
  sed -n 3p "$f" | grep -qx "$(printf '%s' 'unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX')" || bad "$f: line 3 must unset the GIT_* hook env (GIT_DIR leak sets core.bare=true on the parent repo)"
done
if [ -z "${CHECK_NESTED:-}" ]; then
  hk=$(mktemp -d)
  git init -q "$hk/p"
  git -C "$hk/p" -c user.name=t -c user.email=t@t commit -q --allow-empty -m x
  git -C "$hk/p" remote add origin https://example.invalid/p.git
  git -C "$hk/p" worktree add -q "$hk/w" -b w 2>/dev/null
  before=$(git -C "$hk/p" config --local --list | sort)
  GIT_DIR="$hk/p/.git/worktrees/w" GIT_INDEX_FILE="$hk/p/.git/worktrees/w/index" GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=user.email GIT_CONFIG_VALUE_0=leaked@example GIT_CONFIG_KEY_1=user.name GIT_CONFIG_VALUE_1=leaked CHECK_NESTED=1 sh scripts/check.sh >/dev/null 2>&1 || bad "check.sh fails when run with a hook's GIT_DIR"
  after=$(git -C "$hk/p" config --local --list | sort)
  [ "$before" = "$after" ] || bad "check.sh under a hook's GIT_DIR changed the parent repo config: $(printf '%s\n' "$after" | grep -vxF "$before" | tr '\n' ' ')"
  rm -rf "$hk"
fi

ord=$(mktemp -d)
git init -q "$ord/r"
git -C "$ord/r" config user.email t@t
git -C "$ord/r" config user.name t
printf 'ok\n' > "$ord/r/marker"
git -C "$ord/r" add marker
git -C "$ord/r" commit -q -m base
obase=$(git -C "$ord/r" rev-parse HEAD)
printf 'bad\n' > "$ord/r/marker"
git -C "$ord/r" commit -q -am mid
omid=$(git -C "$ord/r" rev-parse HEAD)
printf 'ok\n' > "$ord/r/marker"
git -C "$ord/r" commit -q -am tip
otip=$(git -C "$ord/r" rev-parse HEAD)
printf '#!/bin/sh\necho ran > "%s/hook-ran"\nexit 1\n' "$ord" > "$ord/r/.git/hooks/post-checkout"
chmod +x "$ord/r/.git/hooks/post-checkout"
repo=$(pwd)
st=0
out=$( cd "$ord/r" && "$repo/scripts/check-commit-order.sh" "$obase" -- grep -qx ok marker 2>&1 ) || st=$?
[ "$st" -ne 0 ] || bad "check-commit-order: passes a range whose middle commit is red"
echo "$out" | grep -q "$omid" || bad "check-commit-order: does not name the red commit"
[ "$(git -C "$ord/r" rev-parse HEAD)" = "$otip" ] || bad "check-commit-order: moved HEAD"
[ -z "$(git -C "$ord/r" status --porcelain)" ] || bad "check-commit-order: dirtied the caller worktree"
[ ! -e "$ord/hook-ran" ] || bad "check-commit-order: ran post-checkout"
if git -C "$ord/r" config --local --get core.hooksPath >/dev/null 2>&1; then bad "check-commit-order: set core.hooksPath"; fi
[ "$(git -C "$ord/r" worktree list | wc -l | tr -d ' ')" -eq 1 ] || bad "check-commit-order: left a worktree"
rm -f "$ord/r/.git/hooks/post-checkout"
git -C "$ord/r" checkout -q -b green "$obase"
printf 'ok\n' > "$ord/r/other"
git -C "$ord/r" add other
git -C "$ord/r" commit -q -m good
( cd "$ord/r" && "$repo/scripts/check-commit-order.sh" "$obase" -- grep -qx ok marker >/dev/null ) || bad "check-commit-order: fails an all-green range"
( cd "$ord/r" && "$repo/scripts/check-commit-order.sh" HEAD -- true >/dev/null ) || bad "check-commit-order: empty range failed"
st=0
( cd "$ord/r" && "$repo/scripts/check-commit-order.sh" >/dev/null 2>&1 ) || st=$?
[ "$st" -eq 2 ] || bad "check-commit-order: usage exit $st"
rm -rf "$ord"

[ "$fail" -eq 0 ] && echo "check ok"
exit "$fail"
