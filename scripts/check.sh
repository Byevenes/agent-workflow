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

argv_secret_hit() {
  scan_root=$1
  scan_hit=0
  scan_flag=$(printf '%s%s' '--api-' 'key')
  hits=$(grep -rlF -- "$scan_flag" "$scan_root" || true)
  if [ -n "$hits" ]; then
    printf '%s\n' "argv secret: $scan_flag" "$hits"
    scan_hit=1
  fi
  scan_flag=$(printf '%s%s' '--auth-' 'token')
  hits=$(grep -rlF -- "$scan_flag" "$scan_root" || true)
  if [ -n "$hits" ]; then
    printf '%s\n' "argv secret: $scan_flag" "$hits"
    scan_hit=1
  fi
  return "$scan_hit"
}

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

for f in AGENTS.md rules/zstack.mdc agents/zigl.md agents/opencode/zstack.md skills/route-work/SKILL.md; do
  grep -qF 'skills/zstack/SKILL.md' "$f" || bad "$f: must point at skills/zstack/SKILL.md"
done

for f in skills/zstack/SKILL.md agents/opencode/zstack.md; do
  grep -q -- '--force' "$f" || bad "$f: client rule about --force missing"
  grep -q 'Client slice commits' "$f" || bad "$f: client slice commit rule missing"
done

zs=skills/zstack/SKILL.md
for s in \
  'technology-agnostic' \
  'Never invent checks' \
  'Pre-push gate' \
  'docs/security-scan.md' \
  'gitleaks git --log-opts' \
  'SonarQube for IDE' \
  'client pipeline remains the source of truth' \
  'Recovery case' \
  '### Slice loop' \
  'A recovery plan does not replace that new session' \
  'The next ticket is not started here' \
  'scripts/check-commit-order.sh' \
  'scripts/blast-radius-callers.sh' \
  'Every Task call to zsensei passes model: claude-opus-5-5-medium.' \
  'issue #58' \
  '.cursor/agents/' \
  'scope changed' \
  'git add -A' \
  'never use `--no-verify`' \
  '### Inline without Cursor' \
  'git push --dry-run' \
  'before coding starts' \
  'only the diff' \
  'independent (no Cursor)' \
  'tickets = ceil(tokens_estimados * holgura / 150_000)' \
  'Medium whose estimate is about 150k tokens promotes to Large' \
  'Critical keeps the security path even when the ticket count is 1' \
  '.scratch/<slug>/calibracion.md' \
  'docs/model-matrix.md' \
  '## Modelos' \
  'scripts/sonar-diff-issues.sh' \
  'scripts/check-remote-tests.sh' \
  'scripts/check-export-package.sh' \
  'scripts/mode-for.sh'
do
  grep -qF -- "$s" "$zs" || bad "zstack skill missing phrase: $s"
done
grep -q 'push_checks' docs/examples/clients.toml.example || bad "clients.toml.example: push_checks missing"
grep -q 'scripts/check-commit-order.sh' docs/scripts.md || bad "scripts.md: commit-order gate missing"
grep -qF 'including private methods and indirect callers' skills/blast-radius/SKILL.md || bad "blast-radius skill: private and indirect callers missing"
grep -qF 'The check fails when the report misses one.' skills/blast-radius/SKILL.md || bad "blast-radius skill: coverage failure missing"
grep -q 'scripts/blast-radius-callers.sh' docs/scripts.md || bad "scripts.md: blast-radius caller gate missing"
grep -q 'scripts/blast-radius-callers.sh' agents/zninja.md || bad "zninja: blast-radius caller gate missing"
for f in skills/zstack/SKILL.md docs/testing.md docs/workflow.md docs/software-factory.md docs/scripts.md agents/zninja.md; do
  grep -q 'scripts/classify-test-failures.sh' "$f" || bad "$f: test failure classifier missing"
  grep -qF 'A HEAD failure is env-known only when the same id and the same detail fail on the base branch.' "$f" || bad "$f: env-known rule missing"
  grep -qF 'With no base result, every HEAD failure is real.' "$f" || bad "$f: missing-base rule missing"
done
grep -q 'explicit yes' agents/zninja.md || bad "zninja: out-of-scope bug must stop for an explicit yes"
grep -q 'Do not mix the bugfix and the feature in one commit' agents/zninja.md || bad "zninja: bugfix and feature may share a commit"
grep -q 'the `fix:` commit is an ancestor of the feature commit' agents/zninja.md || bad "zninja: review checklist missing"
fixline=$(grep -n 'fix: keep the empty input on the existing path' agents/zninja.md | head -1 | cut -d: -f1)
featline=$(grep -n "feat: add the ticket's slice" agents/zninja.md | head -1 | cut -d: -f1)
if [ -z "$fixline" ] || [ -z "$featline" ] || [ "$fixline" -ge "$featline" ]; then bad "zninja: fix: example is not before the feature example"; fi
grep -q 'that `fix:` commit is an ancestor of the feature commit' agents/zsensei.md || bad "zsensei: out-of-scope history checklist missing"
grep -qF 'Agreeing with the doc, or with the code, is not enough to drop a finding' agents/zsensei.md || bad "zsensei: doc or code agreement is not a disproof"
grep -qF 'If the previous round reviewed uncommitted work, it had no HEAD_SHA' agents/zsensei.md || bad "zsensei: re-review without a previous HEAD_SHA missing"
grep -qF 'one line per item that is outside this diff or deferred' agents/zsensei.md || bad "zsensei: follow-ups format missing"
zn_front=$(awk 'BEGIN{n=0} /^---$/{n++; if (n==2) exit; next} n==1 {print}' agents/zninja.md)
if printf '%s\n' "$zn_front" | grep -q '^model:'; then bad "zninja: model must stay unset so the subagent inherits"; fi
if printf '%s\n' "$zn_front" | grep -q -- '-fast'; then bad "zninja: must not set a -fast model"; fi
zs_front=$(awk 'BEGIN{n=0} /^---$/{n++; if (n==2) exit; next} n==1 {print}' agents/zsensei.md)
if ! printf '%s\n' "$zs_front" | grep -qx 'model: claude-opus-5-5-medium'; then bad "zsensei: model must be claude-opus-5-5-medium"; fi
if ! printf '%s\n' "$zs_front" | grep -qx 'readonly: true'; then bad "zsensei: readonly must be true"; fi
check_project_agents
nmerge=$(grep -rliF 'Never merge' --exclude-dir=.git --exclude-dir=.scratch --exclude-dir=retros --exclude=check.sh . | wc -l | tr -d ' ')
[ "$nmerge" -eq 1 ] || bad "Never merge must live only in skills/zstack/SKILL.md (found in $nmerge files)"

grep -qF 'independent (no Cursor)' agents/opencode/zstack.md || bad "opencode zstack: independent reviewer missing"
for f in skills/zstack/SKILL.md skills/zpr/SKILL.md; do
  grep -qF 'the diff alone is not the review' "$f" || bad "$f: the diff alone is not the review"
done
grep -qF '## Evidence' skills/zpr/SKILL.md || bad "zpr: ## Evidence section missing"
for f in skills/zgrill/SKILL.md skills/zspec/SKILL.md skills/ztickets/SKILL.md skills/zwayfinder/SKILL.md; do
  grep -qF 'In client repos, never' "$f" || bad "$f: client repos must not publish to a tracker"
done
zw=skills/zwayfinder/SKILL.md
for s in \
  '.scratch/' \
  "without the user's explicit ok" \
  'already ready' \
  'already clear' \
  'run `/wayfinder` manually (I can'"'"'t invoke it)'
do
  grep -qF -- "$s" "$zw" || bad "zwayfinder missing phrase: $s"
done
if grep -q '^disable-model-invocation:' "$zw"; then bad "zwayfinder: must stay model-invocable"; fi
grep -qF 'zwayfinder' scripts/check-delivery-note.sh || bad "delivery-note: zwayfinder missing from the tool pattern"
grep -qF 'zwayfinder' scripts/link.sh || bad "link.sh: zwayfinder missing from the wrapper loop"
grep -qF 'zwayfinder:wayfinder' scripts/setup-check.sh || bad "setup-check: zwayfinder:wayfinder pair missing"
grep -qF 'Use `zwayfinder` when the plan does not fit one session' skills/zstack/SKILL.md || bad "zstack: zwayfinder large-path trigger missing"
grep -qF 'Do not start a map when the spec is already ready or the way is already clear' skills/zstack/SKILL.md || bad "zstack: zwayfinder already-ready guard missing"
cal='.scratch/<slug>/calibracion.md'
grep -qF "$cal" skills/zretro/SKILL.md || bad "zretro: calibration log path missing"
mm=docs/model-matrix.md
for s in \
  'claude-opus-5-5-medium' \
  'claude-opus-5-5-high' \
  'grok-4.7-xhigh' \
  'The review role is Claude Opus fixed' \
  'no quota fallback that downgrades judgment' \
  'inherit-parent'
do
  grep -qF -- "$s" "$mm" || bad "model-matrix missing phrase: $s"
done
for s in \
  'docs/model-matrix.md' \
  '## Modelos' \
  'pendiente' \
  'confirmado' \
  'revertido' \
  'Review every pendiente in the retro log before proposing a new change.'
do
  grep -qF -- "$s" skills/zretro/SKILL.md || bad "zretro skill missing phrase: $s"
done
for s in \
  'fallback = []' \
  'claude-opus-5-5-medium' \
  'grok-4.7-high'
do
  grep -qF -- "$s" docs/examples/model-matrix.toml || bad "model-matrix.toml missing phrase: $s"
done
if grep -qE 'grok-4\.7-medium|-fast' docs/examples/model-matrix.toml; then bad "model-matrix.toml: medium Grok or a -fast slug as a default"; fi
ex=docs/examples/calibracion-large.md
for s in \
  '## Modelos' \
  '| zsensei | review | claude-opus-5-5-high | claude-opus-5-5-high | no |' \
  '| zninja | implement | grok-4.7-xhigh | grok-4.7-xhigh | no |'
do
  grep -qF -- "$s" "$ex" || bad "calibracion-large missing phrase: $s"
done
if [ -e rules/pstack-models.mdc ] || [ -e .cursor/rules/pstack-models.mdc ]; then bad "model-matrix: pstack-models.mdc must stay outside this repo"; fi

if grep -rnE 'SDD|sdd-|tech-lead|test-engineer' skills/zstack rules agents; then bad "zstack copies reference SDD, tech-lead or test-engineer"; fi

if grep -rnE '"subagent_type": *"(implementer|code-reviewer)"|`(implementer|code-reviewer|coordinator)`' skills/zstack rules agents README.md AGENTS.md docs/software-factory.md docs/workflow.md; then bad "old role names in live copies"; fi

for f in scripts/*.sh .githooks/* hooks/client-guard/*; do
  sh -n "$f" || bad "$f: syntax"
  if awk 'NR>1 && /^[[:space:]]*#/ && !/https?:\/\/|SPDX|[Ll]icense/' "$f" | grep -q .; then bad "$f: comment without issue/RFC link or license"; fi
done

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck -e SC2016 scripts/*.sh skills/*/scripts/*.sh .githooks/* hooks/client-guard/* || bad shellcheck
else
  bad "shellcheck missing (brew install shellcheck)"
fi
git_dir_unset=$(printf '%s' 'unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX')
for f in scripts/*.sh; do
  case "$(basename "$f")" in
    mcp-gitlab.sh|mcp-postgres.sh|route-audit.sh|check-repo-paths.sh) continue ;;
  esac
  [ -f "$f" ] || continue
  sed -n 3p "$f" | grep -qx "$git_dir_unset" || bad "$f: line 3 must unset the GIT_* hook env (GIT_DIR leak sets core.bare=true on the parent repo)"
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

if [ "$(date +%Y%m%d)" -ge 20261201 ] && { [ -e skills/route-work ] || grep -q route-work scripts/link.sh; }; then bad "route-work alias expired 2026-12-01: delete skills/route-work and its link.sh lines"; fi

grep -qF 'to-techspec cd39260d948a3a300902272aaf9417d48b68ec54' skills/versions || bad "skills/versions: to-techspec pin missing"
pin_back='delete the line or set the rev to `main` or `HEAD`, then run `scripts/link.sh` again'
grep -qF "$pin_back" docs/scripts.md || bad "scripts.md: return to main missing"
grep -qF "$pin_back" README.md || bad "README: return to main missing"
grep -qF 'fetch-depth: 0' .github/workflows/check.yml || bad "check.yml: fetch-depth 0 missing"

for s in to-analysis client-questionnaire; do
  got=$(awk '/^name:/{ sub(/^name:[[:space:]]*/, ""); gsub(/"/, ""); sub(/[[:space:]]*$/, ""); print; exit }' "skills/$s/SKILL.md" 2>/dev/null || true)
  [ "$got" = "$s" ] || bad "skills/$s: set name to the directory"
done
qfile=skills/client-questionnaire/SKILL.md
if [ ! -f "$qfile" ] \
  || ! grep -q '^## Preguntas$' "$qfile" \
  || ! grep -q '^## Prioridad$' "$qfile" \
  || ! grep -q '^## Bloqueantes$' "$qfile" \
  || ! grep -qE '^Q[0-9]+\. .+ dueño:[A-Za-z]+$' "$qfile" \
  || grep -qE '^## (TL|PO|Infra|QA)$' "$qfile"
then
  bad "client-questionnaire: use headings ## Preguntas, ## Prioridad and ## Bloqueantes, one idea per line, owner at line end as dueño:<rol>"
fi
section0=$(awk '/^## 0\. / { p=1 } /^## 1\. / { p=0 } p' skills/zstack/SKILL.md)
if ! printf '%s\n' "$section0" | grep -q 'client-questionnaire' || printf '%s\n' "$section0" | grep -q 'to-questionnaire'; then
  bad "zstack section 0: client questions use client-questionnaire, not to-questionnaire"
fi
pre_stage=$(awk '/^for s in / { print; exit }' scripts/setup-check.sh)
case $pre_stage in
  *client-questionnaire*) ;;
  *) bad "setup-check.sh: list client-questionnaire in the pre-stage for-loop, not to-questionnaire" ;;
esac
case $pre_stage in
  *to-questionnaire*) bad "setup-check.sh: list client-questionnaire in the pre-stage for-loop, not to-questionnaire" ;;
esac
git check-ignore -q -- .scratch/answers.md || bad ".gitignore: add .scratch/ so scratch notes stay untracked"
tmp=$(mktemp -d)
mkdir -p "$tmp/.cursor/skills/realdir" "$tmp/.config/opencode/skills"
mkdir -p "$tmp/.cursor/skills/to-analysis"
printf 'loose copy\n' > "$tmp/.cursor/skills/to-analysis/SKILL.md"
ln -s "$tmp/nowhere" "$tmp/.cursor/skills/broken"
ln -s "$tmp/nowhere" "$tmp/.config/opencode/skills/broken"
mkdir -p "$tmp/.cursor/plugins/local/other-plugin" "$tmp/.cursor/plugins/local/zstack-agents/agents"
printf 'marker\n' > "$tmp/.cursor/plugins/local/other-plugin/marker"
printf 'canary\n' > "$tmp/plugin-canary"
ln -s "$tmp/plugin-canary" "$tmp/.cursor/plugins/local/zstack-agents/agents/zsensei.md"
unset LINK_SKILL_VERSIONS
HOME=$tmp scripts/link.sh >/dev/null
if [ -L "$tmp/.cursor/skills/broken" ] || [ -L "$tmp/.config/opencode/skills/broken" ]; then bad "link.sh: keeps a broken skill symlink"; fi
[ -d "$tmp/.cursor/skills/realdir" ] || bad "link.sh: removed a real skill folder"
link_root=$(CDPATH='' pwd)
for p in .cursor/skills/to-analysis .config/opencode/skills/to-analysis; do
  if [ ! -L "$tmp/$p" ] || [ "$(readlink "$tmp/$p")" != "$link_root/skills/to-analysis" ] || [ ! -f "$tmp/$p/SKILL.md" ] || grep -qx 'loose copy' "$tmp/$p/SKILL.md"; then
    bad "link.sh: loose to-analysis survived; remove the real directory before link_force so the repo skill replaces it"
  fi
done
grep -rqx 'loose copy' "$tmp/.cache/agent-workflow/replaced-skills" 2>/dev/null || bad "link.sh: a loose skill folder was deleted; move it under ~/.cache/agent-workflow/replaced-skills instead"
for p in .cursor/skills/client-questionnaire .config/opencode/skills/client-questionnaire; do
  if [ ! -L "$tmp/$p" ] || [ ! -f "$tmp/$p/SKILL.md" ]; then
    bad "link.sh: client-questionnaire not force-linked; add it next to to-techspec in the link_force loop"
  fi
done
for p in .cursor/skills/zstack/scripts/route-audit.sh .config/opencode/skills/zstack/scripts/route-audit.sh; do
  [ -x "$tmp/$p" ] || bad "link.sh smoke: $p not executable through the zstack link"
done
for p in .cursor/skills/zspec/scripts/check-repo-paths.sh .config/opencode/skills/zspec/scripts/check-repo-paths.sh; do
  [ -x "$tmp/$p" ] || bad "link.sh smoke: $p not executable through the zspec link"
done
for p in .cursor/skills/zstack .cursor/skills/zgrill .cursor/skills/zwayfinder .cursor/skills/zpr .cursor/skills/blast-radius .cursor/rules/zstack.mdc .cursor/agents/zninja.md .config/opencode/skills/zstack .config/opencode/skills/blast-radius .config/opencode/zstack.md .config/opencode/agents/zstack.md; do
  if [ ! -L "$tmp/$p" ] || [ ! -e "$tmp/$p" ]; then bad "link.sh smoke: $p not linked"; fi
done
plug="$tmp/.cursor/plugins/local/zstack-agents"
manifest="$plug/.cursor-plugin/plugin.json"
if [ ! -f "$manifest" ]; then
  bad "link.sh: plugin manifest missing"
else
  grep -q '"name": "zstack-agents"' "$manifest" || bad "link.sh: plugin manifest name missing"
  grep -q '"agents": "./agents/"' "$manifest" || bad "link.sh: plugin manifest agents path missing"
fi
for agent in zigl zninja zsensei; do
  p="$plug/agents/$agent.md"
  if [ -L "$p" ] || [ ! -f "$p" ]; then bad "link.sh: plugin agent $agent is not a regular file"; fi
  cmp -s "agents/$agent.md" "$p" || bad "link.sh: plugin agent $agent differs from the repo"
done
cmp -s "$tmp/plugin-canary" - <<'EOF' || bad "link.sh: followed the zsensei symlink and changed the canary"
canary
EOF
cmp -s "$tmp/.cursor/plugins/local/other-plugin/marker" - <<'EOF' || bad "link.sh: changed a sibling plugin marker"
marker
EOF
HOME=$tmp scripts/link.sh >/dev/null
for agent in zigl zninja zsensei; do
  p="$plug/agents/$agent.md"
  if [ -L "$p" ] || [ ! -f "$p" ]; then bad "link.sh: second run plugin agent $agent is not a regular file"; fi
  cmp -s "agents/$agent.md" "$p" || bad "link.sh: second run plugin agent $agent differs from the repo"
done
pin=cd39260d948a3a300902272aaf9417d48b68ec54
repo_root=$(CDPATH='' pwd)
want=$(mktemp)
git show "$pin:skills/to-techspec/SKILL.md" >"$want"
for p in .cursor/skills/to-techspec .config/opencode/skills/to-techspec; do
  target=$(readlink "$tmp/$p")
  case "$target" in
    *agent-workflow/skills/to-techspec/"$pin"*) ;;
    *) bad "link.sh: $p is not pinned at $pin" ;;
  esac
  cmp -s "$want" "$tmp/$p/SKILL.md" || bad "link.sh: $p text differs from $pin"
done
rm -f "$want"
[ "$(readlink "$tmp/.cursor/skills/zstack")" = "$repo_root/skills/zstack" ] || bad "link.sh: zstack left the checkout"
pinned_once=$(readlink "$tmp/.cursor/skills/to-techspec")
HOME=$tmp scripts/link.sh >/dev/null
[ "$(readlink "$tmp/.cursor/skills/to-techspec")" = "$pinned_once" ] || bad "link.sh: second run moved to-techspec"
old=38536b1f66b1e3f84277efa939812937228092ce
vf=$(mktemp)
printf '%s\n' "to-techspec $old" >"$vf"
h=$(mktemp -d)
HOME=$h LINK_SKILL_VERSIONS=$vf scripts/link.sh >/dev/null
want=$(mktemp)
git show "$old:skills/to-techspec/SKILL.md" >"$want"
cmp -s "$want" "$h/.cursor/skills/to-techspec/SKILL.md" || bad "link.sh: override pin text differs from $old"
if grep -qE '(^|[^/])scripts/check-repo-paths\.sh' "$h/.cursor/skills/to-techspec/SKILL.md"; then bad "link.sh: override pin still has the checkout marker"; fi
[ "$(readlink "$h/.cursor/skills/zgrill")" = "$repo_root/skills/zgrill" ] || bad "link.sh: zgrill left the checkout"
rm -rf "$h"
rm -f "$want"
for rev in HEAD main; do
  printf '%s\n' "to-techspec $rev" >"$vf"
  h=$(mktemp -d)
  HOME=$h LINK_SKILL_VERSIONS=$vf scripts/link.sh >/dev/null
  [ "$(readlink "$h/.cursor/skills/to-techspec")" = "$repo_root/skills/to-techspec" ] || bad "link.sh: rev $rev left the checkout"
  [ "$(readlink "$h/.config/opencode/skills/to-techspec")" = "$repo_root/skills/to-techspec" ] || bad "link.sh: rev $rev left the opencode checkout"
  rm -rf "$h"
done
(
  trap 'git tag -d skill-pin-fixture >/dev/null 2>&1 || true' EXIT
  git tag -d skill-pin-fixture >/dev/null 2>&1 || true
  git tag skill-pin-fixture "$old"
  printf '%s\n' 'to-techspec skill-pin-fixture' >"$vf"
  h=$(mktemp -d)
  HOME=$h LINK_SKILL_VERSIONS=$vf scripts/link.sh >/dev/null || exit 1
  git show 'skill-pin-fixture:skills/to-techspec/SKILL.md' >"$h/want"
  cmp -s "$h/want" "$h/.cursor/skills/to-techspec/SKILL.md" || exit 1
  rm -rf "$h"
) || bad "link.sh: tag pin text differs"
if [ -n "$(git tag -l skill-pin-fixture)" ]; then bad "link.sh: skill-pin-fixture tag survived"; fi
printf '%s\n' 'to-techspec deadbeefdeadbeefdeadbeefdeadbeefdeadbeef' >"$vf"
h=$(mktemp -d)
err=$(mktemp)
if HOME=$h LINK_SKILL_VERSIONS=$vf scripts/link.sh >/dev/null 2>"$err"; then
  bad "link.sh: accepts an unknown rev"
fi
grep -q to-techspec "$err" || bad "link.sh: unknown rev stderr omits to-techspec"
if [ -e "$h/.cursor/skills/to-techspec" ] || [ -L "$h/.cursor/skills/to-techspec" ]; then bad "link.sh: unknown rev linked to-techspec"; fi
if [ -e "$h/.cursor/skills/zstack" ] || [ -L "$h/.cursor/skills/zstack" ]; then bad "link.sh: unknown rev linked zstack"; fi
rm -rf "$h"
rm -f "$vf" "$err"
check_project_agents
rm -rf "$tmp"

sh scripts/check-draft-sections.sh --example docs/examples/unslop-before-after.md >/dev/null || bad "unslop: required sections missing"
d=$(mktemp -d)
err=$d/err
printf '%s\n' '## Resumen' uno '## Hallazgos' dos '## Incertidumbres' tres '## Fuentes' cuatro > "$d/es.md"
env -u ZSTACK_MAX_QUESTIONS_PER_OWNER sh scripts/check-draft-sections.sh analysis "$d/es.md" >/dev/null || bad "analysis: Spanish headings should pass"
printf '%s\n' '## Resumen de la HU' '## Hallazgos' '## Incertidumbres' '## Fuentes' > "$d/sub.md"
if env -u ZSTACK_MAX_QUESTIONS_PER_OWNER sh scripts/check-draft-sections.sh analysis "$d/sub.md" >/dev/null 2>"$err"; then bad "analysis: a longer heading must not satisfy ## Resumen"; fi
grep -qF 'fail analysis: missing ## Resumen' "$err" || bad "analysis: substring heading should name ## Resumen"
printf '%s\n' '## Context' '## Findings' '## Uncertainties' '## Sources' > "$d/en.md"
if env -u ZSTACK_MAX_QUESTIONS_PER_OWNER sh scripts/check-draft-sections.sh analysis "$d/en.md" >/dev/null 2>"$err"; then bad "analysis: English headings should fail"; fi
grep -qF 'fail analysis: missing ## Resumen' "$err" || bad "analysis: English stderr should name ## Resumen"
sh scripts/check-draft-sections.sh qa-inputs docs/examples/insumos-qa.md >/dev/null || bad "qa-inputs: template should pass"
grep -vF '## Fuera de alcance' docs/examples/insumos-qa.md > "$d/qa.md"
if sh scripts/check-draft-sections.sh qa-inputs "$d/qa.md" >/dev/null 2>"$err"; then bad "qa-inputs: missing Fuera de alcance should fail"; fi
grep -qF 'fail qa-inputs: missing ## Fuera de alcance' "$err" || bad "qa-inputs: stderr should name ## Fuera de alcance"
awk 'BEGIN{print "## Preguntas"; for(i=1;i<=12;i++) printf "Q%d. item %d dueño:QA\n", i, i; print "## Prioridad"; print "## Bloqueantes"}' > "$d/q12.md"
env -u ZSTACK_MAX_QUESTIONS_PER_OWNER sh scripts/check-draft-sections.sh questionnaire "$d/q12.md" >/dev/null || bad "questionnaire: 12 for one owner should pass"
awk 'BEGIN{print "## Preguntas"; for(i=1;i<=16;i++) printf "Q%d. item %d dueño:QA\n", i, i; print "## Prioridad"; print "## Bloqueantes"}' > "$d/q16.md"
if env -u ZSTACK_MAX_QUESTIONS_PER_OWNER sh scripts/check-draft-sections.sh questionnaire "$d/q16.md" >/dev/null 2>"$err"; then bad "questionnaire: 16 for one owner should fail"; fi
grep -qF 'fail questionnaire: dueño:QA has 16 questions, max 15 (set ZSTACK_MAX_QUESTIONS_PER_OWNER)' "$err" || bad "questionnaire: cap stderr"
ZSTACK_MAX_QUESTIONS_PER_OWNER=0 sh scripts/check-draft-sections.sh questionnaire "$d/q16.md" >/dev/null || bad "questionnaire: cap 0 should disable"
awk 'BEGIN{print "## Preguntas"; for(i=1;i<=15;i++) printf "Q%d. qa %d dueño:QA\n", i, i; for(i=16;i<=30;i++) printf "Q%d. tl %d dueño:TL\n", i, i; print "## Prioridad"; print "## Bloqueantes"}' > "$d/both.md"
env -u ZSTACK_MAX_QUESTIONS_PER_OWNER sh scripts/check-draft-sections.sh questionnaire "$d/both.md" >/dev/null || bad "questionnaire: 15 per owner should pass"
printf '%s\n' '## Preguntas' 'Q1. ¿El informe incluye filas? dueño:QA' 'Q2. el informe incluye filas dueño:TL' '## Prioridad' '## Bloqueantes' > "$d/dup.md"
if env -u ZSTACK_MAX_QUESTIONS_PER_OWNER sh scripts/check-draft-sections.sh questionnaire "$d/dup.md" >/dev/null 2>"$err"; then bad "questionnaire: duplicate questions should fail"; fi
grep -qF 'duplicates an earlier question; drop the copy' "$err" || bad "questionnaire: duplicate stderr"
printf '%s\n' '## Supuestos' '¿El informe incluye filas?' '## Fuentes' ticket > "$d/sup.md"
printf '%s\n' '## Preguntas' 'Q1. El informe incluye filas. dueño:QA' '## Prioridad' '## Bloqueantes' > "$d/rep.md"
if env -u ZSTACK_MAX_QUESTIONS_PER_OWNER sh scripts/check-draft-sections.sh questionnaire "$d/rep.md" --analysis "$d/sup.md" >/dev/null 2>"$err"; then bad "questionnaire: a supuesto repeat should fail"; fi
grep -qF 'fail questionnaire: Q1 repeats a supuesto' "$err" || bad "questionnaire: supuesto stderr"
printf '%s\n' '## Preguntas' '## QA' '## Prioridad' '## Bloqueantes' > "$d/extra.md"
if env -u ZSTACK_MAX_QUESTIONS_PER_OWNER sh scripts/check-draft-sections.sh questionnaire "$d/extra.md" >/dev/null 2>"$err"; then bad "questionnaire: extra heading should fail"; fi
grep -qF 'fail questionnaire: extra heading ## QA; put the owner at line end as dueño:<rol>' "$err" || bad "questionnaire: extra heading stderr"
printf '%s\n' '## Preguntas' 'Q1. falta el rol' '## Prioridad' '## Bloqueantes' > "$d/nodueno.md"
if env -u ZSTACK_MAX_QUESTIONS_PER_OWNER sh scripts/check-draft-sections.sh questionnaire "$d/nodueno.md" >/dev/null 2>"$err"; then bad "questionnaire: missing dueño should fail"; fi
grep -qF 'has no dueño; add dueño:<rol> at line end' "$err" || bad "questionnaire: dueño stderr"
qfx=docs/examples/questionnaire-frontier-fixtures
env -u ZSTACK_MAX_QUESTIONS_PER_OWNER sh scripts/check-draft-sections.sh questionnaire "$qfx/ronda-1.md" >/dev/null || bad "questionnaire frontier: ronda 1 with only ready bloqueantes should pass"
if env -u ZSTACK_MAX_QUESTIONS_PER_OWNER sh scripts/check-draft-sections.sh questionnaire "$qfx/dependiente-colada.md" >/dev/null 2>"$err"; then bad "questionnaire frontier: a question whose dependency is pendiente should fail"; fi
grep -qF 'fail questionnaire: Q2 in ## Ronda actual depends on Q1 (pendiente); ask Q1 first and hold Q2 for a later round' "$err" || bad "questionnaire frontier: dependency stderr"
awk '/^## Preguntas$/,0' "$qfile" > "$d/qtpl.md"
env -u ZSTACK_MAX_QUESTIONS_PER_OWNER sh scripts/check-draft-sections.sh questionnaire "$d/qtpl.md" >/dev/null || bad "client-questionnaire: the template must pass check-draft-sections"
grep -qF 'depende de:' "$qfile" || bad "client-questionnaire: document depende de"
grep -qF '## Ronda actual' "$qfile" || bad "client-questionnaire: document ## Ronda actual"
sed -e 's/^- Q5$/- Q5\
- Q8/' "$qfx/ronda-1.md" > "$d/nobloq.md"
if env -u ZSTACK_MAX_QUESTIONS_PER_OWNER sh scripts/check-draft-sections.sh questionnaire "$d/nobloq.md" >/dev/null 2>"$err"; then bad "questionnaire frontier: a non-bloqueante question before the bloqueantes should fail"; fi
grep -qF 'Q8 in ## Ronda actual is not bloqueante' "$err" || bad "questionnaire frontier: non-bloqueante stderr"
grep -vxF -- '- Q3' "$qfx/ronda-1.md" > "$d/falta.md"
if env -u ZSTACK_MAX_QUESTIONS_PER_OWNER sh scripts/check-draft-sections.sh questionnaire "$d/falta.md" >/dev/null 2>"$err"; then bad "questionnaire frontier: a missing frontier question should fail"; fi
grep -qF 'Q3 is on the frontier' "$err" || bad "questionnaire frontier: missing frontier stderr"
sed -e 's/^- Q5$/- Q5\
- Q4/' "$qfx/ronda-1.md" > "$d/resp.md"
if env -u ZSTACK_MAX_QUESTIONS_PER_OWNER sh scripts/check-draft-sections.sh questionnaire "$d/resp.md" >/dev/null 2>"$err"; then bad "questionnaire frontier: a respondida question in the round should fail"; fi
grep -qF 'Q4 in ## Ronda actual is respondida' "$err" || bad "questionnaire frontier: respondida stderr"
awk '
  $0 == "Q1. ¿El reporte mensual se exporta en CSV o en XLSX? dueño:PO" { print; getline; print "  estado:respondida bloqueante:sí depende de:-"; next }
  $0 == "Q3. ¿El reporte incluye filas sin categoría? dueño:PO" { print; getline; print "  estado:respondida bloqueante:sí depende de:-"; next }
  $0 == "Q5. ¿La exportación corre en el mismo job nocturno que hoy? dueño:Infra" { print; getline; print "  estado:respondida bloqueante:sí depende de:Q4"; next }
  $0 == "## Ronda actual" { print; print "- Q2"; r = 1; next }
  r && /^- Q/ { next }
  { r = 0; print }
' "$qfx/ronda-1.md" > "$d/ronda-2.md"
env -u ZSTACK_MAX_QUESTIONS_PER_OWNER sh scripts/check-draft-sections.sh questionnaire "$d/ronda-2.md" >/dev/null 2>"$err" || bad "questionnaire frontier: ronda 2 after Q1 respondida should pass: $(cat "$err")"
grep -vF '  estado:pendiente bloqueante:sí depende de:Q4' "$qfx/ronda-1.md" > "$d/sinestado.md"
if env -u ZSTACK_MAX_QUESTIONS_PER_OWNER sh scripts/check-draft-sections.sh questionnaire "$d/sinestado.md" >/dev/null 2>"$err"; then bad "questionnaire frontier: a question without estado line should fail"; fi
grep -qF 'Q5 has no estado line' "$err" || bad "questionnaire frontier: estado line stderr"
sed -e 's/depende de:Q1$/depende de:Q9/' "$qfx/ronda-1.md" > "$d/q9.md"
if env -u ZSTACK_MAX_QUESTIONS_PER_OWNER sh scripts/check-draft-sections.sh questionnaire "$d/q9.md" >/dev/null 2>"$err"; then bad "questionnaire frontier: an unknown dependency should fail"; fi
grep -qF 'Q2 depends on Q9, which is not a question' "$err" || bad "questionnaire frontier: unknown dependency stderr"
awk 'BEGIN{print "## Preguntas"; for(i=1;i<=16;i++) { printf "Q%d. item %d dueño:QA\n", i, i; print "  estado:" (i == 1 ? "pendiente" : "respondida") " bloqueante:sí depende de:-" } print "## Ronda actual"; print "- Q1"; print "## Prioridad"; print "## Bloqueantes"}' > "$d/f16.md"
env -u ZSTACK_MAX_QUESTIONS_PER_OWNER sh scripts/check-draft-sections.sh questionnaire "$d/f16.md" >/dev/null || bad "questionnaire frontier: the cap counts only pendiente questions"
awk 'BEGIN{print "## Preguntas"; for(i=1;i<=16;i++) { printf "Q%d. item %d dueño:QA\n", i, i; print "  estado:pendiente bloqueante:sí depende de:-" } print "## Ronda actual"; for(i=1;i<=16;i++) printf "- Q%d\n", i; print "## Prioridad"; print "## Bloqueantes"}' > "$d/p16.md"
if env -u ZSTACK_MAX_QUESTIONS_PER_OWNER sh scripts/check-draft-sections.sh questionnaire "$d/p16.md" >/dev/null 2>"$err"; then bad "questionnaire frontier: 16 pendiente for one owner should fail"; fi
grep -qF 'fail questionnaire: dueño:QA has 16 pendiente questions, max 15 (set ZSTACK_MAX_QUESTIONS_PER_OWNER)' "$err" || bad "questionnaire frontier: cap stderr"
printf '%s\n' "$section0" | grep -qF 'the parent runs scripts/prestage-handoff.sh' || bad "zstack section 0: parent runs prestage-handoff"
root=$(pwd)
trap 'rm -rf "$d"' EXIT
if (cd "$d" && sh "$root/scripts/check-prestage-kdb.sh" >/dev/null 2>"$err"); then bad "kdb: missing sidecar should fail"; fi
grep -qF 'fail kdb: missing .scratch/kdb-used.txt; write kdb: <files read> or kdb: none found (<reason>)' "$err" || bad "kdb: missing sidecar stderr"
printf 'n\n' > "$d/notes.md"
printf 'o\n' > "$d/other.md"
printf 'kdb: %s\n' "$d/notes.md" > "$d/side.txt"
sh "$root/scripts/check-prestage-kdb.sh" "$d/side.txt" >/dev/null || bad "kdb: one file should pass"
printf 'kdb: %s, %s\n' "$d/notes.md" "$d/other.md" > "$d/side.txt"
sh "$root/scripts/check-prestage-kdb.sh" "$d/side.txt" >/dev/null || bad "kdb: two files should pass"
printf '%s\n' 'kdb: none found (no matching root)' > "$d/side.txt"
sh "$root/scripts/check-prestage-kdb.sh" "$d/side.txt" >/dev/null || bad "kdb: none found should pass"
printf 'kdb: %s\n' "$d/missing.md" > "$d/side.txt"
if sh "$root/scripts/check-prestage-kdb.sh" "$d/side.txt" >/dev/null 2>"$err"; then bad "kdb: absent path should fail"; fi
grep -qF "fail kdb: $d/missing.md is not a file" "$err" || bad "kdb: absent path stderr"
mkdir -p "$d/.scratch"
printf '%s\n' 'ninguno' > "$d/.scratch/privado.md"
printf '%s\n' 'kdb: notes.md' > "$d/.scratch/kdb-used.txt"
(cd "$d" && sh "$root/scripts/prestage-handoff.sh" analysis "$d/es.md" >/dev/null) || bad "prestage: spanish draft with sidecar should pass"
rm -f "$d/.scratch/kdb-used.txt"
if (cd "$d" && sh "$root/scripts/prestage-handoff.sh" analysis "$d/es.md" >/dev/null 2>"$err"); then bad "prestage: missing sidecar should fail"; fi
grep -qF 'fail kdb: missing .scratch/kdb-used.txt; write kdb: <files read> or kdb: none found (<reason>)' "$err" || bad "prestage: missing sidecar stderr"
printf '%s\n' '## Context' > "$d/context.md"
printf '%s\n' 'kdb: notes.md' > "$d/.scratch/kdb-used.txt"
if (cd "$d" && sh "$root/scripts/prestage-handoff.sh" analysis "$d/context.md" >/dev/null 2>"$err"); then bad "prestage: context-only draft should fail"; fi
grep -qF 'fail analysis: missing ## Resumen' "$err" || bad "prestage: context-only stderr"
rm -f "$d/.scratch/kdb-used.txt"
if (cd "$d" && sh "$root/scripts/prestage-handoff.sh" analysis "$d/context.md" >/dev/null 2>"$err"); then bad "prestage: both checks should fail"; fi
grep -qF 'fail analysis: missing ## Resumen' "$err" || bad "prestage: both should name Resumen"
grep -qF 'fail kdb: missing .scratch/kdb-used.txt; write kdb: <files read> or kdb: none found (<reason>)' "$err" || bad "prestage: both should name the sidecar"
printf '%s\n' '```topics' "$(printf 'sesion\tlogin,otp,lockout\tauth-spi')" '```' > "$d/topics.md"
printf '%s\n' 'El login probablemente vive en el sitio base.' > "$d/concl.md"
if sh "$root/scripts/check-topic-repos.sh" --kdb "$d/topics.md" --draft "$d/concl.md" >/dev/null 2>"$err"; then bad "topic: conclusion without repo should fail"; fi
grep -qF 'fail topic sesion: concluded without repo auth-spi' "$err" || bad "topic: conclusion stderr"
printf '%s\n' 'Q1. ¿Dónde está el login? repo-ausente: auth-spi' > "$d/qtopic.md"
sh "$root/scripts/check-topic-repos.sh" --kdb "$d/topics.md" --draft "$d/qtopic.md" >/dev/null || bad "topic: Q repo-ausente should pass"
mkdir -p "$d/present/auth-spi"
sh "$root/scripts/check-topic-repos.sh" --kdb "$d/topics.md" --draft "$d/concl.md" --present "$d/present/auth-spi" >/dev/null || bad "topic: present repo should allow a conclusion"
sh "$root/scripts/check-topic-repos.sh" --kdb "$d/notes.md" --draft "$d/concl.md" >/dev/null || bad "topic: kdb without a topics fence should pass"
printf '%s\n' '## Resumen' visible '## Hallazgos' dos '## Incertidumbres' tres '## Fuentes' cuatro > "$d/clean.md"
printf '%s\n' 'ninguno' > "$d/priv-none.md"
sh "$root/scripts/check-client-surface.sh" "$d/clean.md" "$d/priv-none.md" >/dev/null || bad "surface: clean deliverable should pass"
printf '%s\n' '## Resumen' 'INTERNO: detalle que se queda en el scratch' '## Hallazgos' dos '## Incertidumbres' tres '## Fuentes' cuatro > "$d/interno.md"
if sh "$root/scripts/check-client-surface.sh" "$d/interno.md" "$d/priv-none.md" >/dev/null 2>"$err"; then bad "surface: INTERNO in the deliverable should fail"; fi
grep -qF 'fail surface: INTERNO line belongs in the private file' "$err" || bad "surface: INTERNO stderr"
printf '%s\n' 'INTERNO: detalle que se queda en el scratch' > "$d/priv.md"
sh "$root/scripts/check-client-surface.sh" "$d/clean.md" "$d/priv.md" >/dev/null || bad "surface: INTERNO only in the private file should pass"
printf '%s\n' '## Resumen' "$(printf '%s\n' '-----BEGIN '"PRIVATE KEY"'-----')" '## Hallazgos' dos '## Incertidumbres' tres '## Fuentes' cuatro > "$d/key.md"
if sh "$root/scripts/check-client-surface.sh" "$d/key.md" "$d/priv-none.md" >/dev/null 2>"$err"; then bad "surface: key block should fail"; fi
grep -qF 'fail surface: key block belongs in the private file' "$err" || bad "surface: key block stderr"
printf '%s\n' '## Resumen' "$(printf '%s%s%s' 'postgres' '://app:' 'pw@db.example.test/app')" '## Hallazgos' dos '## Incertidumbres' tres '## Fuentes' cuatro > "$d/conn-uri.md"
if sh "$root/scripts/check-client-surface.sh" "$d/conn-uri.md" "$d/priv-none.md" >/dev/null 2>"$err"; then bad "surface: connection uri should fail"; fi
grep -qF 'fail surface: connection string in the deliverable' "$err" || bad "surface: connection uri stderr"
printf '%s\n' '## Resumen' 'Server=db.example.test;User ID=app;Password=pw;' '## Hallazgos' dos '## Incertidumbres' tres '## Fuentes' cuatro > "$d/conn-kv.md"
if sh "$root/scripts/check-client-surface.sh" "$d/conn-kv.md" "$d/priv-none.md" >/dev/null 2>"$err"; then bad "surface: key-value connection should fail"; fi
grep -qF 'fail surface: connection string in the deliverable' "$err" || bad "surface: key-value connection stderr"
printf '%s\n' '## Resumen' 'The password is not in the code. See https://example.test/docs' '## Hallazgos' dos '## Incertidumbres' tres '## Fuentes' cuatro > "$d/conn-ok.md"
sh "$root/scripts/check-client-surface.sh" "$d/conn-ok.md" "$d/priv-none.md" >/dev/null || bad "surface: https url without a connection string should pass"
printf '%s\n' '## Resumen' 'password=pw and guid=abc' '## Hallazgos' dos '## Incertidumbres' tres '## Fuentes' cuatro > "$d/conn-guid.md"
sh "$root/scripts/check-client-surface.sh" "$d/conn-guid.md" "$d/priv-none.md" >/dev/null || bad "surface: guid assignment should pass"
if sh "$root/scripts/check-client-surface.sh" "$d/clean.md" "$d/missing-priv.md" >/dev/null 2>"$err"; then bad "surface: missing privado should fail"; fi
grep -qF 'fail surface: write .scratch/privado.md (even if ninguno)' "$err" || bad "surface: missing privado stderr"
printf '%s\n' '## Resumen' 'El login probablemente vive en el sitio base.' '## Hallazgos' dos '## Incertidumbres' tres '## Fuentes' cuatro > "$d/an-login.md"
printf 'kdb: %s\n' "$d/topics.md" > "$d/.scratch/kdb-used.txt"
if (cd "$d" && sh "$root/scripts/prestage-handoff.sh" analysis "$d/an-login.md" >/dev/null 2>"$err"); then bad "prestage: topic conclusion should fail"; fi
grep -qF 'fail topic sesion: concluded without repo auth-spi' "$err" || bad "prestage: topic conclusion stderr"
printf '%s\n' '## Resumen' 'Q1. ¿Dónde está el login? repo-ausente: auth-spi' '## Hallazgos' dos '## Incertidumbres' tres '## Fuentes' cuatro > "$d/an-q.md"
(cd "$d" && sh "$root/scripts/prestage-handoff.sh" analysis "$d/an-q.md" >/dev/null) || bad "prestage: topic question should pass"
er=$(mktemp -d)
git init -q -b main "$er/r"
git -C "$er/r" config user.email t@t
git -C "$er/r" config user.name t
mkdir -p "$er/r/helm"
printf '%s\n' 'widgetFlag: on' > "$er/r/helm/values.yaml"
git -C "$er/r" add helm/values.yaml
git -C "$er/r" commit -q -m 'keep widgetFlag on purpose'
git -C "$er/r" checkout -q -b other
printf '%s\n' x > "$er/r/extra"
git -C "$er/r" add extra
git -C "$er/r" commit -q -m extra
git -C "$er/r" checkout -q main
probe=$(sh "$root/scripts/evidence-probe.sh" --repo "$er/r" --token widgetFlag)
printf '%s\n' "$probe" | grep -qF 'config: found helm/values.yaml' || bad "probe: values path: $probe"
printf '%s\n' "$probe" | grep -qF 'history: found keep widgetFlag on purpose' || bad "probe: history subject: $probe"
printf '%s\n' '## Resumen' 'el token' '## Hallazgos' dos '## Incertidumbres' tres '## Fuentes' cuatro > "$d/nofence.md"
if sh "$root/scripts/check-claims.sh" --repo "$er/r" --draft "$d/nofence.md" >/dev/null 2>"$err"; then bad "claims: missing fence should fail"; fi
grep -qF 'fail claims: add a claims fence' "$err" || bad "claims: missing fence stderr"
printf '%s\n' '## Resumen' 'el `widgetFlag` está ausente' '```claims' ninguno '```' '## Hallazgos' dos '## Incertidumbres' tres '## Fuentes' cuatro > "$d/ausente.md"
if sh "$root/scripts/check-claims.sh" --repo "$er/r" --draft "$d/ausente.md" >/dev/null 2>"$err"; then bad "claims: ausente in values should fail"; fi
grep -qF 'fail evidence: widgetFlag is in deploy values' "$err" || bad "claims: ausente stderr"
printf '%s\n' '## Resumen' 'el `widgetFlag` es un bug' '```claims' ninguno '```' '## Hallazgos' dos '## Incertidumbres' tres '## Fuentes' cuatro > "$d/bug.md"
if sh "$root/scripts/check-claims.sh" --repo "$er/r" --draft "$d/bug.md" >/dev/null 2>"$err"; then bad "claims: bug without subject should fail"; fi
grep -qF 'fail evidence: quote the git log -S subject' "$err" || bad "claims: bug stderr"
printf '%s\n' '## Resumen' 'el `widgetFlag` es un bug' 'keep widgetFlag on purpose' '```claims' ninguno '```' '## Hallazgos' dos '## Incertidumbres' tres '## Fuentes' cuatro > "$d/bugok.md"
sh "$root/scripts/check-claims.sh" --repo "$er/r" --draft "$d/bugok.md" >/dev/null || bad "claims: bug with subject should pass"
printf '%s\n' '## Resumen' 'el `widgetFlag` es un bug' 'the commit keep widgetFlag on purpose landed yesterday' '```claims' ninguno '```' '## Hallazgos' dos '## Incertidumbres' tres '## Fuentes' cuatro > "$d/bugsent.md"
if sh "$root/scripts/check-claims.sh" --repo "$er/r" --draft "$d/bugsent.md" >/dev/null 2>"$err"; then bad "claims: subject in a sentence should fail"; fi
grep -qF 'fail evidence: quote the git log -S subject' "$err" || bad "claims: sentence stderr"
printf '%s\n' '## Resumen' 'el `widgetFlag` es un bug' 'keep widgetFlag on purposely' '```claims' ninguno '```' '## Hallazgos' dos '## Incertidumbres' tres '## Fuentes' cuatro > "$d/bugpart.md"
if sh "$root/scripts/check-claims.sh" --repo "$er/r" --draft "$d/bugpart.md" >/dev/null 2>"$err"; then bad "claims: partial subject should fail"; fi
grep -qF 'fail evidence: quote the git log -S subject' "$err" || bad "claims: partial stderr"
printf '%s\n' '## Resumen' 'el `widgetFlag` es un bug' '`keep widgetFlag on purpose`' '```claims' ninguno '```' '## Hallazgos' dos '## Incertidumbres' tres '## Fuentes' cuatro > "$d/bugcite.md"
sh "$root/scripts/check-claims.sh" --repo "$er/r" --draft "$d/bugcite.md" >/dev/null || bad "claims: backtick citation should pass"
printf '%s\n' '## Resumen' nada '```claims' ninguno '```' '## Hallazgos' dos '## Incertidumbres' tres '## Fuentes' cuatro 'ramas-fuera-de-base: ninguna' > "$d/nobr.md"
if sh "$root/scripts/check-unmerged-branches.sh" --repo "$er/r" --draft "$d/nobr.md" >/dev/null 2>"$err"; then bad "branches: unnamed other should fail"; fi
grep -qF 'fail branches: other not named' "$err" || bad "branches: unnamed stderr"
printf '%s\n' '## Resumen' 'rama other' '```claims' ninguno '```' '## Hallazgos' dos '## Incertidumbres' tres '## Fuentes' cuatro > "$d/named.md"
sh "$root/scripts/check-unmerged-branches.sh" --repo "$er/r" --draft "$d/named.md" >/dev/null || bad "branches: named other should pass"
printf '%s\n' '## Resumen' 'another' '```claims' ninguno '```' '## Hallazgos' dos '## Incertidumbres' tres '## Fuentes' cuatro > "$d/substr.md"
if sh "$root/scripts/check-unmerged-branches.sh" --repo "$er/r" --draft "$d/substr.md" >/dev/null 2>"$err"; then bad "branches: another should not name other"; fi
grep -qF 'fail branches: other not named' "$err" || bad "branches: substring stderr"
if sh "$root/scripts/check-unmerged-branches.sh" --repo "$er/r" --draft "$d/named.md" --base missing >/dev/null 2>"$err"; then bad "branches: missing base should fail"; fi
grep -qF 'fail branches: base missing is missing' "$err" || bad "branches: missing base stderr"
printf '%s\n' 'ramas-fuera-de-base: ninguna' > "$d/baseother.md"
sh "$root/scripts/check-unmerged-branches.sh" --repo "$er/r" --draft "$d/baseother.md" --base other >/dev/null || bad "branches: --base other should pass"
printf '%s\n' "$er/r" > "$d/.scratch/present-repos.txt"
if (cd "$d" && sh "$root/scripts/prestage-handoff.sh" analysis "$d/ausente.md" >/dev/null 2>"$err"); then bad "prestage: ausente claim should fail"; fi
grep -qF 'fail evidence: widgetFlag is in deploy values' "$err" || bad "prestage: ausente stderr"
grep -qF 'fail branches: other not named' "$err" || bad "prestage: should also name the unmerged branch"
rm -rf "$er"
rm -rf "$d"
trap - EXIT
ra=$(mktemp -d)
mkdir -p "$ra/p/agent-transcripts"
printf '%s\n' 'zstack: small, full verifiable' '"name":"Write"' 'zninja launched: no (inline: Task tool absent)' > "$ra/p/agent-transcripts/ok.jsonl"
ROUTE_AUDIT_BASE=$ra scripts/route-audit.sh >/dev/null || bad "route-audit: fails on a clean fixture"
printf '%s\n' 'zstack: small, full verifiable' '"name":"Write"' > "$ra/p/agent-transcripts/noreason.jsonl"
if ROUTE_AUDIT_BASE=$ra scripts/route-audit.sh >/dev/null; then bad "route-audit: passes an inline edit without a reason"; fi
rm "$ra/p/agent-transcripts/noreason.jsonl"
printf '%s\n' 'zstack: medium, full verifiable' '"name":"Write"' '"subagent_type":"zninja"' > "$ra/p/agent-transcripts/norev.jsonl"
ROUTE_AUDIT_BASE=$ra scripts/route-audit.sh >/dev/null || bad "route-audit: fails a Medium edit with zninja and without zsensei"
rm "$ra/p/agent-transcripts/norev.jsonl"
printf '%s\n' '{"role":"assistant","message":{"content":[{"type":"text","text":"Clasificación **Medium** (zstack): dos piezas."}]}}' '{"type":"tool_use","name":"Write"}' '{"subagent_type":"zninja"}' > "$ra/p/agent-transcripts/real.jsonl"
ROUTE_AUDIT_BASE=$ra scripts/route-audit.sh >/dev/null || bad "route-audit: fails a real-format Medium transcript with zninja and without zsensei"
rm "$ra/p/agent-transcripts/real.jsonl"
printf '%s\n' 'zstack: large, full verifiable' '"name":"Write"' '"subagent_type":"zninja"' > "$ra/p/agent-transcripts/norev.jsonl"
if ROUTE_AUDIT_BASE=$ra scripts/route-audit.sh >/dev/null; then bad "route-audit: passes a Large edit with zninja and without zsensei"; fi
rm "$ra/p/agent-transcripts/norev.jsonl"
printf '%s\n' 'zstack: critical, full verifiable' '"name":"Write"' '"subagent_type":"zninja"' > "$ra/p/agent-transcripts/norev.jsonl"
if ROUTE_AUDIT_BASE=$ra scripts/route-audit.sh >/dev/null; then bad "route-audit: passes a Critical edit with zninja and without zsensei"; fi
rm "$ra/p/agent-transcripts/norev.jsonl"
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
ROUTE_AUDIT_BASE=$ra skills/zstack/scripts/route-audit.sh >/dev/null || bad "route-audit: skill copy fails on a clean fixture"
ra_case() {
  rc_dir=$(mktemp -d)
  mkdir -p "$rc_dir/p/agent-transcripts"
  rc_n=0
  for rc_body in "$@"; do
    rc_n=$((rc_n + 1))
    printf '%s\n' "$rc_body" | tr '|' '\n' >"$rc_dir/p/agent-transcripts/s$rc_n.jsonl"
  done
  rc_rc=0
  ROUTE_AUDIT_BASE=$rc_dir scripts/route-audit.sh >/dev/null || rc_rc=1
  rm -rf "$rc_dir"
  return "$rc_rc"
}
w_code='{"name":"Write","input":{"path":"/w/src/App/Service.cs"'
w_test='{"name":"StrReplace","input":{"path":"/w/test/App.Tests/ServiceTests.cs"'
w_rep='{"name":"Write","input":{"path":"/w/.scratch/review.md"'
ra_case "zstack: Critical, full verifiable — delegated fix: x|zstack delegated: fix|$w_code" "zstack: Critical, partial verifiable — delegated review: x|zstack delegated: review|$w_rep" || bad "route-audit: fails a delegated Critical fix with a delegated review"
if ra_case "zstack: Critical, full verifiable — delegated fix: x|zstack delegated: fix|$w_code"; then bad "route-audit: passes a delegated Critical fix with no review"; fi
ra_case "zstack: Critical, partial verifiable — review|$w_rep|zninja launched: no (inline: review only)" || bad "route-audit: counts a report under .scratch/ as a code edit"
ra_case "zstack: Medium, full verifiable — x|$w_test|zninja launched: no (orchestrator-fix: delegated run could not delete an empty test file)" || bad "route-audit: fails an orchestrator test fix with a reason"
if ra_case "zstack: Medium, full verifiable — x|$w_code|zninja launched: no (orchestrator-fix: quick)"; then bad "route-audit: passes an orchestrator fix outside tests"; fi
if ra_case "zstack: Medium, full verifiable — x|$w_test"; then bad "route-audit: passes an orchestrator test fix without a reason"; fi
if ra_case "zstack: Medium, full verifiable — x|zstack delegated: review|$w_code"; then bad "route-audit: passes a delegated review that edited code"; fi
rm -rf "$ra"

cd_t=$(mktemp -d)
printf '%s\n' '#!/bin/sh' 'printf "%s\n" "$@" >"$CD_ARGS"' 'echo "{\"type\":\"result\",\"result\":\"ok\"}"' >"$cd_t/agent"
printf '%s\n' '#!/bin/sh' 'sleep 30 &' 'echo $! >"$CD_CHILD"' 'wait' >"$cd_t/slow"
chmod +x "$cd_t/agent" "$cd_t/slow"
echo 'task' >"$cd_t/p.md"
CD_ARGS=$cd_t/args AGENT_BIN=$cd_t/agent scripts/cursor-delegate.sh --workspace "$cd_t" --prompt "$cd_t/p.md" --role fix --size critical --verifiable full --reason r --out "$cd_t/o.jsonl" || bad "cursor-delegate: fails a clean run"
grep -qx -- '--trust' "$cd_t/args" || bad "cursor-delegate: --trust missing"
grep -A1 -x -- '--sandbox' "$cd_t/args" | grep -qx enabled || bad "cursor-delegate: --sandbox enabled missing by default"
if grep -Eqx -- '--force|--yolo|-f' "$cd_t/args"; then bad "cursor-delegate: passes a force flag"; fi
grep -qF 'no harness or script in `/tmp`' "$cd_t/args" || bad "cursor-delegate: prompt lacks the no-improvised-runner rule"
grep -qx 'exit=0' "$cd_t/o.jsonl.meta" || bad "cursor-delegate: meta lacks exit=0"
grep -qF 'zstack: Critical, full verifiable — delegated fix: r' "$cd_t/args" || bad "cursor-delegate: prompt lacks the canonical zstack line"
grep -qx 'zstack delegated: fix' "$cd_t/args" || bad "cursor-delegate: prompt lacks the delegated role line"
if AGENT_BIN=$cd_t/agent scripts/cursor-delegate.sh --workspace "$cd_t" --prompt "$cd_t/p.md" --out "$cd_t/n.jsonl" 2>/dev/null; then bad "cursor-delegate: runs without role and size"; fi
CD_ARGS=$cd_t/args AGENT_BIN=$cd_t/agent scripts/cursor-delegate.sh --workspace "$cd_t" --prompt "$cd_t/p.md" --role fix --size critical --verifiable full --reason r --out "$cd_t/a.jsonl" --approval auto-review || bad "cursor-delegate: fails an auto-review run"
grep -qx -- '--auto-review' "$cd_t/args" || bad "cursor-delegate: --auto-review not passed"
if CD_ARGS=$cd_t/args AGENT_BIN=$cd_t/agent scripts/cursor-delegate.sh --workspace "$cd_t" --prompt "$cd_t/p.md" --role fix --size critical --verifiable full --reason r --out "$cd_t/x.jsonl" --model m-fast 2>/dev/null; then bad "cursor-delegate: accepts a -fast model"; fi
rc=0
CD_CHILD=$cd_t/child AGENT_BIN=$cd_t/slow DELEGATE_IDLE=2 scripts/cursor-delegate.sh --workspace "$cd_t" --prompt "$cd_t/p.md" --role fix --size critical --verifiable full --reason r --out "$cd_t/s.jsonl" 2>/dev/null || rc=$?
[ "$rc" = 124 ] || bad "cursor-delegate: idle run not killed with 124 (got $rc)"
grep -q '^exit=killed(idle' "$cd_t/s.jsonl.meta" || bad "cursor-delegate: meta lacks killed(idle)"
if [ -s "$cd_t/child" ] && kill -0 "$(cat "$cd_t/child")" 2>/dev/null; then bad "cursor-delegate: idle kill left the agent's child running"; fi
rm -rf "$cd_t"

cg=$(mktemp -d)
git init -q "$cg/r"
(cd "$cg/r" && HOME=$cg CLIENTS_ROOT='' "$OLDPWD/hooks/client-guard/pre-push" origin https://github.com/Byevenes/x.git >/dev/null) || bad "client-guard: blocks a personal GitHub push"
if (cd "$cg/r" && HOME=$cg CLIENTS_ROOT='' "$OLDPWD/hooks/client-guard/pre-push" origin git@bitbucket.org:client/x.git >/dev/null); then bad "client-guard: allows a bitbucket push"; fi
mkdir -p "$cg/Clients/c"
git init -q "$cg/Clients/c/r"
if (cd "$cg/Clients/c/r" && HOME=$cg CLIENTS_ROOT='' "$OLDPWD/hooks/client-guard/pre-push" origin https://github.com/c/x.git >/dev/null); then bad "client-guard: allows a push under the clients root"; fi
(cd "$cg/Clients/c/r" && HOME=$cg CLIENTS_ROOT='' CLIENT_PUSH_OK=brayan "$OLDPWD/hooks/client-guard/pre-push" origin x </dev/null >/dev/null) || bad "client-guard: ignores CLIENT_PUSH_OK=brayan"
(cd "$cg/r" && HOME=$cg CLIENTS_ROOT='' "$OLDPWD/hooks/client-guard/pre-commit" >/dev/null) || bad "client-guard pre-commit: blocks a personal repo"
if (cd "$cg/Clients/c/r" && HOME=$cg CLIENTS_ROOT='' "$OLDPWD/hooks/client-guard/pre-commit" >/dev/null); then bad "client-guard pre-commit: allows a commit under the clients root"; fi
git -C "$cg/r" remote add origin git@gitlab.com:client/x.git
if (cd "$cg/r" && HOME=$cg CLIENTS_ROOT='' "$OLDPWD/hooks/client-guard/pre-commit" >/dev/null); then bad "client-guard pre-commit: allows a commit with a gitlab origin"; fi
(cd "$cg/Clients/c/r" && HOME=$cg CLIENTS_ROOT='' CLIENT_PUSH_OK=brayan "$OLDPWD/hooks/client-guard/pre-commit" >/dev/null) || bad "client-guard pre-commit: ignores CLIENT_PUSH_OK=brayan"
rm -rf "$cg"

pc=$(mktemp -d)
pc_repo=$pc/repo
pc_bin=$PWD/hooks/client-guard/push-checks
pc_hook=$PWD/hooks/client-guard/pre-push
pc_run() {
  pc_rc=0
  pc_out=$(cd "$pc_repo" && "$@") || pc_rc=$?
}
pc_run_all() {
  pc_rc=0
  pc_out=$(cd "$pc_repo" && "$@" 2>&1) || pc_rc=$?
}
pc_has() {
  if ! printf '%s\n' "$pc_out" | grep -qF -- "$1"; then
    bad "push-checks: missing $1"
  fi
}
pc_lacks() {
  if printf '%s\n' "$pc_out" | grep -qF -- "$1"; then
    bad "push-checks: unexpected $1"
  fi
}
pc_commit() {
  git -C "$pc_repo" add "$1"
  git -C "$pc_repo" -c user.name=Test -c user.email=user@example.com commit -q -m "$2"
}
git init -q "$pc_repo"
git -C "$pc_repo" symbolic-ref HEAD refs/heads/main
printf 'base\n' > "$pc_repo/readme.txt"
pc_commit readme.txt base
b0=$(git -C "$pc_repo" rev-parse HEAD)
git -C "$pc_repo" checkout -q -B cfg-ok "$b0"
printf 'more\n' >> "$pc_repo/readme.txt"
pc_commit readme.txt ok
c_ok=$(git -C "$pc_repo" rev-parse HEAD)
git -C "$pc_repo" checkout -q -B cfg-bad "$b0"
printf '{}\n' > "$pc_repo/appsettings.json"
pc_commit appsettings.json cfg
c_cfg=$(git -C "$pc_repo" rev-parse HEAD)
git -C "$pc_repo" checkout -q -B sens-ok "$b0"
printf '%s\n' 'user@example.com' > "$pc_repo/note.txt"
pc_commit note.txt mail
c_mail=$(git -C "$pc_repo" rev-parse HEAD)
pc_rut=$(printf '%s.%s.%s-%s' '11' '111' '111' '1')
pc_bad_mail=$(printf '%s@%s.%s' 'user' 'mail' 'invalid')
git -C "$pc_repo" checkout -q -B sens-bad "$b0"
printf '%s\n' "$pc_rut" "$pc_bad_mail" > "$pc_repo/id.txt"
pc_commit id.txt sens
c_sens=$(git -C "$pc_repo" rev-parse HEAD)
git -C "$pc_repo" checkout -q -B sens-del "$c_sens"
printf 'gone\n' > "$pc_repo/id.txt"
pc_commit id.txt del
c_del=$(git -C "$pc_repo" rev-parse HEAD)
git -C "$pc_repo" checkout -q -B cfg-next "$c_cfg"
printf 'later\n' >> "$pc_repo/readme.txt"
pc_commit readme.txt later
c_cfg2=$(git -C "$pc_repo" rev-parse HEAD)
pc_run env CLIENT_SKIP_GITLEAKS=1 "$pc_bin" "$b0" "$c_ok" ABC-123
[ "$pc_rc" -eq 0 ] || bad "push-checks: config pass rc=$pc_rc"
pc_has "ok push-checks"
pc_lacks "fail config"
pc_lacks "fail branch"
pc_run env CLIENT_SKIP_GITLEAKS=1 "$pc_bin" "$b0" "$c_cfg" ABC-123
[ "$pc_rc" -ne 0 ] || bad "push-checks: config fail expected non-zero"
pc_has "fail config: appsettings.json"
pc_lacks "ok push-checks"
pc_run env CLIENT_SKIP_GITLEAKS=1 CLIENT_ALLOW_CONFIG=1 "$pc_bin" "$b0" "$c_cfg" ABC-123
[ "$pc_rc" -eq 0 ] || bad "push-checks: config override rc=$pc_rc"
pc_has "warn config: appsettings.json"
pc_has "ok push-checks"
pc_lacks "fail config"
pc_run env CLIENT_SKIP_GITLEAKS=1 CLIENT_ALLOW_CONFIG=true "$pc_bin" "$b0" "$c_cfg" ABC-123
[ "$pc_rc" -ne 0 ] || bad "push-checks: config override must be exact 1"
pc_has "fail config: appsettings.json"
pc_run env CLIENT_SKIP_GITLEAKS=1 "$pc_bin" "$b0" "$c_mail" ABC-123
[ "$pc_rc" -eq 0 ] || bad "push-checks: allowed email rc=$pc_rc"
pc_lacks "fail sensitive"
pc_run env CLIENT_SKIP_GITLEAKS=1 "$pc_bin" "$b0" "$c_sens" ABC-123
[ "$pc_rc" -ne 0 ] || bad "push-checks: sensitive fail expected non-zero"
pc_has "fail sensitive: id.txt 2"
pc_lacks "ok push-checks"
if printf '%s\n' "$pc_out" | grep -qF -- "$pc_rut"; then bad "push-checks: output contains a matched value"; fi
if printf '%s\n' "$pc_out" | grep -qF -- "$pc_bad_mail"; then bad "push-checks: output contains a matched value"; fi
pc_run env CLIENT_SKIP_GITLEAKS=1 CLIENT_ALLOW_SENSITIVE=1 "$pc_bin" "$b0" "$c_sens" ABC-123
[ "$pc_rc" -eq 0 ] || bad "push-checks: sensitive override rc=$pc_rc"
pc_has "warn sensitive: id.txt 2"
pc_has "ok push-checks"
if printf '%s\n' "$pc_out" | grep -qF -- "$pc_rut"; then bad "push-checks: warn output contains a matched value"; fi
pc_run env CLIENT_SKIP_GITLEAKS=1 "$pc_bin" "$c_sens" "$c_del" ABC-123
[ "$pc_rc" -eq 0 ] || bad "push-checks: deleted value rc=$pc_rc"
pc_lacks "fail sensitive"
pc_run env CLIENT_SKIP_GITLEAKS=1 "$pc_bin" "$b0" "$c_ok" topic
[ "$pc_rc" -ne 0 ] || bad "push-checks: branch fail expected non-zero"
pc_has "fail branch: topic"
pc_lacks "ok push-checks"
pc_run env CLIENT_SKIP_GITLEAKS=1 CLIENT_ALLOW_BRANCH=1 "$pc_bin" "$b0" "$c_ok" topic
[ "$pc_rc" -eq 0 ] || bad "push-checks: branch override rc=$pc_rc"
pc_has "warn branch: topic"
pc_has "ok push-checks"
mkdir -p "$pc/bin"
printf '%s\n' '#!/bin/sh' 'printf "%s\n" "$@" >"$GL_ARGS"' 'printf "%s\n" GL-CANARY' 'printf "%s\n" GL-CANARY >&2' 'if [ "${GL_EXIT:-0}" = 1 ]; then exit 1; fi' 'exit 0' > "$pc/bin/gitleaks"
chmod +x "$pc/bin/gitleaks"
rm -f "$pc/args"
pc_run_all env PATH="$pc/bin:/bin:/usr/bin" GL_ARGS="$pc/args" GL_EXIT=0 "$pc_bin" "$b0" "$c_ok" ABC-123
[ "$pc_rc" -eq 0 ] || bad "push-checks: tokens pass rc=$pc_rc"
pc_has "ok push-checks"
pc_lacks "fail tokens"
pc_lacks "GL-CANARY"
grep -qF -- '--no-banner' "$pc/args" || bad "push-checks: gitleaks argv lacks --no-banner"
grep -qF -- '--log-opts' "$pc/args" || bad "push-checks: gitleaks argv lacks --log-opts"
grep -qE -- '--log-opts=[0-9a-f]+[.][.][0-9a-f]+$' "$pc/args" || bad "push-checks: log-opts is not a parsed range"
rm -f "$pc/args"
pc_run_all env PATH="$pc/bin:/bin:/usr/bin" GL_ARGS="$pc/args" GL_EXIT=1 "$pc_bin" "$b0" "$c_ok" ABC-123
[ "$pc_rc" -ne 0 ] || bad "push-checks: tokens fail expected non-zero"
pc_has "fail tokens: gitleaks"
pc_lacks "ok push-checks"
pc_lacks "GL-CANARY"
grep -qF -- '--no-banner' "$pc/args" || bad "push-checks: failing gitleaks argv lacks --no-banner"
grep -qF -- '--log-opts' "$pc/args" || bad "push-checks: failing gitleaks argv lacks --log-opts"
rm -f "$pc/args"
pc_run env PATH="$pc/bin:/bin:/usr/bin" GL_ARGS="$pc/args" CLIENT_SKIP_GITLEAKS=1 "$pc_bin" "$b0" "$c_ok" ABC-123
[ "$pc_rc" -eq 0 ] || bad "push-checks: skip gitleaks rc=$pc_rc"
pc_has "skip tokens: CLIENT_SKIP_GITLEAKS"
[ ! -f "$pc/args" ] || bad "push-checks: CLIENT_SKIP_GITLEAKS ran gitleaks"
pc_run env PATH="/bin:/usr/bin" "$pc_bin" "$b0" "$c_ok" ABC-123
[ "$pc_rc" -eq 0 ] || bad "push-checks: missing gitleaks rc=$pc_rc"
pc_has "skip tokens: gitleaks missing"
pc_lacks "fail tokens"
rm -f "$pc/args"
pc_run_all env PATH="$pc/bin:/bin:/usr/bin" GL_ARGS="$pc/args" GL_EXIT=1 "$pc_bin" "$b0" "$b0" ABC-123
[ "$pc_rc" -eq 0 ] || bad "push-checks: empty range rc=$pc_rc"
pc_has "ok push-checks"
pc_lacks "fail tokens"
[ ! -f "$pc/args" ] || bad "push-checks: empty range ran gitleaks"
git -C "$pc_repo" checkout -q -B net-empty "$b0"
pc_net_rut=$(printf '%s.%s.%s-%s' '22' '222' '222' 'k')
printf '%s\n' "$pc_net_rut" > "$pc_repo/appsettings.json"
pc_commit appsettings.json net-add
git -C "$pc_repo" rm -q -- appsettings.json
git -C "$pc_repo" -c user.name=Test -c user.email=user@example.com commit -q -m net-drop
c_net=$(git -C "$pc_repo" rev-parse HEAD)
[ "$(git -C "$pc_repo" rev-parse 'HEAD^{tree}')" = "$(git -C "$pc_repo" rev-parse "$b0^{tree}")" ] || bad "push-checks: cancelled range fixture trees differ"
rm -f "$pc/args"
pc_run_all env PATH="$pc/bin:/bin:/usr/bin" GL_ARGS="$pc/args" GL_EXIT=1 "$pc_bin" "$b0" "$c_net" ABC-123
[ "$pc_rc" -ne 0 ] || bad "push-checks: cancelled range rc=$pc_rc"
pc_has "fail config: appsettings.json"
pc_has "fail sensitive: appsettings.json"
pc_has "fail tokens: gitleaks"
pc_lacks "ok push-checks"
if printf '%s\n' "$pc_out" | grep -qF -- "$pc_net_rut"; then bad "push-checks: cancelled range output contains a matched value"; fi
[ -f "$pc/args" ] || bad "push-checks: cancelled range did not run gitleaks"
grep -qF -- '--no-banner' "$pc/args" || bad "push-checks: cancelled range gitleaks argv lacks --no-banner"
grep -qF -- '--log-opts' "$pc/args" || bad "push-checks: cancelled range gitleaks argv lacks --log-opts"
rm -f "$pc/args"
pc_run_all env PATH="$pc/bin:/bin:/usr/bin" GL_ARGS="$pc/args" GL_EXIT=0 "$pc_bin" "" "$c_ok" ABC-123
[ "$pc_rc" -eq 0 ] || bad "push-checks: empty base rc=$pc_rc"
grep -qF -- '--log-opts' "$pc/args" || bad "push-checks: empty base did not call gitleaks"
grep -qE -- '--log-opts=[0-9a-f]+ --not --remotes$' "$pc/args" || bad "push-checks: empty base log-opts is not head --not --remotes"
pc_run env CLIENT_SKIP_GITLEAKS=1 "$pc_bin" "$b0" "$c_ok" ABC-123-main
[ "$pc_rc" -eq 0 ] || bad "push-checks: missing main ref rc=$pc_rc"
pc_has "skip main-branch: origin/main missing"
pc_has "ok push-checks"
git -C "$pc_repo" update-ref refs/remotes/origin/main "$b0"
pc_run env CLIENT_SKIP_GITLEAKS=1 "$pc_bin" "$b0" "$c_ok" ABC-123-main
[ "$pc_rc" -eq 0 ] || bad "push-checks: main-branch pass rc=$pc_rc"
pc_has "ok push-checks"
pc_lacks "fail main-branch"
pc_lacks "skip main-branch"
pc_run env CLIENT_SKIP_GITLEAKS=1 CLIENT_ALLOW_CONFIG=1 "$pc_bin" "$b0" "$c_cfg" ABC-123-main
[ "$pc_rc" -ne 0 ] || bad "push-checks: main-branch still fails when only config is allowed"
pc_has "warn config: appsettings.json"
pc_has "fail main-branch: appsettings.json"
pc_lacks "ok push-checks"
pc_run env CLIENT_SKIP_GITLEAKS=1 "$pc_bin" "$c_cfg" "$c_cfg2" ABC-123-main
[ "$pc_rc" -ne 0 ] || bad "push-checks: main-branch fail expected non-zero"
pc_has "fail main-branch: appsettings.json"
pc_lacks "fail config"
pc_run env CLIENT_SKIP_GITLEAKS=1 CLIENT_ALLOW_MAIN_CONFIG=1 "$pc_bin" "$c_cfg" "$c_cfg2" ABC-123-main
[ "$pc_rc" -eq 0 ] || bad "push-checks: main-branch override rc=$pc_rc"
pc_has "warn main-branch: appsettings.json"
pc_has "ok push-checks"
pc_lacks "fail main-branch"
z40=$(printf '%040d' 0)
ph=$(mktemp -d)
mkdir -p "$ph/Clients/app"
git init -q "$ph/Clients/app/r"
printf 'ok\n' > "$ph/Clients/app/r/readme.txt"
git -C "$ph/Clients/app/r" add readme.txt
git -C "$ph/Clients/app/r" -c user.name=Test -c user.email=user@example.com commit -q -m base
ph_sha=$(git -C "$ph/Clients/app/r" rev-parse HEAD)
ph_rc=0
ph_out=$(printf '%s %s %s %s\n' refs/heads/noticket "$ph_sha" refs/heads/noticket "$z40" | (cd "$ph/Clients/app/r" && HOME=$ph CLIENTS_ROOT='' CLIENT_PUSH_OK=brayan CLIENT_SKIP_GITLEAKS=1 "$pc_hook" origin git@bitbucket.org:client/x.git)) || ph_rc=$?
[ "$ph_rc" -ne 0 ] || bad "pre-push: bad range expected non-zero"
printf '%s\n' "$ph_out" | grep -qF 'fail branch: noticket' || bad "pre-push: bad range missing fail branch"
if printf '%s\n' "$ph_out" | grep -qF 'push allowed'; then bad "pre-push: bad range printed the allow line"; fi
ph_rc=0
ph_out=$(printf '%s %s %s %s\n' refs/heads/ABC-123 "$ph_sha" refs/heads/ABC-123 "$z40" | (cd "$ph/Clients/app/r" && HOME=$ph CLIENTS_ROOT='' CLIENT_PUSH_OK=brayan CLIENT_SKIP_GITLEAKS=1 "$pc_hook" origin git@bitbucket.org:client/x.git)) || ph_rc=$?
[ "$ph_rc" -eq 0 ] || bad "pre-push: clean range rc=$ph_rc"
printf '%s\n' "$ph_out" | grep -qF 'client-guard: push allowed by CLIENT_PUSH_OK=brayan' || bad "pre-push: clean range missing allow line"
ph_rc=0
ph_out=$(printf '%s %s %s %s\n' refs/heads/noticket "$z40" refs/heads/noticket "$z40" | (cd "$ph/Clients/app/r" && HOME=$ph CLIENTS_ROOT='' CLIENT_PUSH_OK=brayan CLIENT_SKIP_GITLEAKS=1 "$pc_hook" origin git@bitbucket.org:client/x.git)) || ph_rc=$?
[ "$ph_rc" -eq 0 ] || bad "pre-push: delete rc=$ph_rc"
printf '%s\n' "$ph_out" | grep -qF 'client-guard: push allowed by CLIENT_PUSH_OK=brayan' || bad "pre-push: delete missing allow line"
cp "$pc_hook" "$ph/pre-push"
chmod +x "$ph/pre-push"
ph_rc=0
ph_out=$(printf '%s %s %s %s\n' refs/heads/noticket "$ph_sha" refs/heads/noticket "$z40" | (cd "$ph/Clients/app/r" && HOME=$ph CLIENTS_ROOT='' CLIENT_PUSH_OK=brayan "$ph/pre-push" origin git@bitbucket.org:client/x.git)) || ph_rc=$?
[ "$ph_rc" -eq 0 ] || bad "pre-push: missing push-checks rc=$ph_rc"
printf '%s\n' "$ph_out" | grep -qF 'client-guard: push-checks not installed, content checks skipped' || bad "pre-push: missing push-checks skip line"
printf '%s\n' "$ph_out" | grep -qF 'client-guard: push allowed by CLIENT_PUSH_OK=brayan' || bad "pre-push: missing push-checks allow line"
git init -q "$ph/personal"
ph_rc=0
ph_out=$(printf '%s %s %s %s\n' refs/heads/noticket "$ph_sha" refs/heads/noticket "$z40" | (cd "$ph/personal" && HOME=$ph CLIENTS_ROOT='' "$pc_hook" origin https://github.com/Byevenes/x.git)) || ph_rc=$?
[ "$ph_rc" -eq 0 ] || bad "pre-push: non-client with stdin rc=$ph_rc"
if printf '%s\n' "$ph_out" | grep -qF 'fail '; then bad "pre-push: non-client ran content checks"; fi
rm -rf "$pc" "$ph"

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

rp_tl=$(printf '\176')
for f in skills/zspec/SKILL.md skills/to-techspec/SKILL.md; do
  if grep -qE '(^|[^/])scripts/check-repo-paths\.sh' "$f"; then
    bad "repo-paths: $f tells the agent to run scripts/check-repo-paths.sh"
  fi
  grep -qF "$rp_tl/.cursor/skills/zspec/scripts/check-repo-paths.sh" "$f" || bad "repo-paths: $f missing the Cursor path to check-repo-paths.sh"
  grep -qF "$rp_tl/.config/opencode/skills/zspec/scripts/check-repo-paths.sh" "$f" || bad "repo-paths: $f missing the OpenCode path to check-repo-paths.sh"
done
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
rp_has "does not exist from the repo root" "appsettings.Development.json"
rp_has "does not exist from the repo root" "src/appsettings.Development.json"
rp_has "does not exist from the repo root" "src/Foo.CS"
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

rp_fence=docs/examples/repo-path-fixtures/fence-dirty.md
rp_fence_status=0
rp_fence_out=$(sh scripts/check-repo-paths.sh "$rp_fence" "$rp_root" 2>&1) || rp_fence_status=$?
[ "$rp_fence_status" -ne 0 ] || bad "repo-paths: fence dirty fixture passed"
printf '%s\n' "$rp_fence_out" | grep -qF 'absolute path: /Users/x/secret.cs' || bad "repo-paths: fence dirty fixture did not report absolute path: /Users/x/secret.cs"
rp_fence_n=$(printf '%s\n' "$rp_fence_out" | grep -cF 'absolute path: /Users/x/secret.cs' || true)
[ "$rp_fence_n" -eq 1 ] || bad "repo-paths: fence dirty fixture reported absolute path: /Users/x/secret.cs ${rp_fence_n} times"
if printf '%s\n' "$rp_fence_out" | grep -qF 'unclosed fence'; then bad "repo-paths: fence dirty fixture reported an unclosed fence"; fi
rp_open=docs/examples/repo-path-fixtures/fence-unclosed.md
rp_open_status=0
rp_open_out=$(sh scripts/check-repo-paths.sh "$rp_open" "$rp_root" 2>&1) || rp_open_status=$?
[ "$rp_open_status" -ne 0 ] || bad "repo-paths: unclosed fence fixture passed"
printf '%s\n' "$rp_open_out" | grep -qF 'fail repo-paths: unclosed fence' || bad "repo-paths: unclosed fence fixture did not report fail repo-paths: unclosed fence"
if printf '%s\n' "$rp_open_out" | grep -qF 'ok repo-paths'; then bad "repo-paths: unclosed fence fixture printed ok repo-paths"; fi
rp_quote=docs/examples/repo-path-fixtures/fence-quote.md
rp_quote_status=0
rp_quote_out=$(sh scripts/check-repo-paths.sh "$rp_quote" "$rp_root" 2>&1) || rp_quote_status=$?
[ "$rp_quote_status" -ne 0 ] || bad "repo-paths: quoted fence fixture passed"
rp_quote_has() {
  printf '%s\n' "$rp_quote_out" | grep -qF -- "$1" || bad "repo-paths: quoted fence fixture did not report $1"
}
rp_quote_lacks() {
  if printf '%s\n' "$rp_quote_out" | grep -qF -- "$1"; then bad "repo-paths: quoted fence fixture reported $1"; fi
}
rp_quote_lacks "src/QuoteMissing.cs"
rp_quote_lacks "src/NestedMissing.cs"
rp_quote_lacks "src/CalloutMissing.cs"
rp_quote_lacks "src/TildeMissing.cs"
rp_quote_lacks "unclosed fence"
rp_quote_has "does not exist from the repo root: src/AfterQuoteMissing.cs"
rp_quote_has "does not exist from the repo root: src/AfterCalloutMissing.cs"
rp_quote_has "does not exist from the repo root: src/QuoteBareMissing.cs"
rp_quote_has "does not exist from the repo root: src/QuoteInlineMissing.cs"
rp_inline=docs/examples/repo-path-fixtures/fence-inline.md
rp_inline_status=0
rp_inline_out=$(sh scripts/check-repo-paths.sh "$rp_inline" "$rp_root" 2>&1) || rp_inline_status=$?
[ "$rp_inline_status" -ne 0 ] || bad "repo-paths: inline fence fixture passed"
if printf '%s\n' "$rp_inline_out" | grep -qF 'unclosed fence'; then bad "repo-paths: inline fence fixture reported an unclosed fence"; fi
rp_inline_has() {
  printf '%s\n' "$rp_inline_out" | grep -qF -- "$1" || bad "repo-paths: inline fence fixture did not report $1"
}
rp_inline_has "does not exist from the repo root: src/InlineMissing.cs"
rp_inline_has "does not exist from the repo root: src/AfterInlineMissing.cs"
rp_inline_has "does not exist from the repo root: src/MidlineMissing.cs"

sec=docs/security-scan.md
if [ ! -f "$sec" ]; then
  bad "security-scan: playbook missing"
else
  for s in \
    'SonarQube for IDE' \
    'gitleaks git --log-opts="<base>..HEAD" --redact' \
    'gitleaks git --redact' \
    'Never install a hook into a client repo' \
    'Never commit security scanner config into a client repo' \
    '.git/info/exclude' \
    'CodeQL is a poor fit for this repo' \
    '## Future / optional' \
    'SonarQube Community' \
    'connected mode'
  do
    grep -qF -- "$s" "$sec" || bad "security-scan: playbook missing $s"
  done
fi
gl=.github/workflows/gitleaks.yml
if [ ! -f "$gl" ]; then
  bad "gitleaks: workflow missing"
else
  for s in 'contents: read' 'fetch-depth: 0' '--redact' '8.30.1' '551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb'; do
    grep -qF -- "$s" "$gl" || bad "gitleaks: workflow missing $s"
  done
  if grep -q pull_request_target "$gl"; then bad "gitleaks: workflow uses pull_request_target"; fi
fi
help=$(sh scripts/setup-check.sh --help)
printf '%s\n' "$help" | grep -qF 'docs/security-scan.md' || bad "setup-check: help misses the security-scan playbook"
grep -qF 'docs/security-scan.md' docs/scripts.md || bad "scripts.md: security-scan playbook missing"
grep -qF 'gitleaks: present' docs/scripts.md || bad "scripts.md: gitleaks status line missing"
grep -qF 'ok gitleaks: present' scripts/setup-check.sh || bad "setup-check: gitleaks present line missing"
grep -qF 'warn gitleaks: missing' scripts/setup-check.sh || bad "setup-check: gitleaks missing warn missing"
out=$(sh scripts/setup-check.sh || true)
printf '%s\n' "$out" | grep -Eq '^(ok|warn) gitleaks: (present|missing)' || bad "setup-check: gitleaks status line missing at runtime"

lesson=docs/examples/kdb-lesson-timezone.md
[ -f "$lesson" ] || bad "timezone lesson: missing"
for s in 'como UTC' 'Normaliza' 'TZ'
do
  grep -qF -- "$s" "$lesson" || bad "timezone lesson missing phrase: $s"
done

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

sec=$(mktemp -d)
printf '%s\n' 'export CURSOR_API_KEY' > "$sec/env.sh"
argv_secret_hit "$sec" || bad "argv secret check fails a script that only names the env var"
printf '%s\n' "agent $(printf '%s%s' '--api-' 'key')" > "$sec/flag.sh"
if argv_secret_hit "$sec" >/dev/null 2>&1; then bad "argv secret check passes a script that passes the key flag on argv"; fi
rm -f "$sec/flag.sh"
printf '%s\n' "agent $(printf '%s%s' '--auth-' 'token')" > "$sec/token.sh"
if argv_secret_hit "$sec" >/dev/null 2>&1; then bad "argv secret check passes a script that passes the auth token flag on argv"; fi
rm -rf "$sec"
for scan_root in scripts hooks .githooks; do
  argv_secret_hit "$scan_root" || bad "argv secret flag in $scan_root"
done

br=docs/examples/blast-radius-fixtures
sh scripts/blast-radius-callers.sh "$br/graph.txt" Order.Save --expect "$br/save-callers.txt" >/dev/null || bad "blast-radius: full caller fixture failed"
st=0
bout=$(mktemp)
sh scripts/blast-radius-callers.sh "$br/graph.txt" Order.Save --expect "$br/public-only.txt" >"$bout" 2>&1 || st=$?
[ "$st" -eq 1 ] || bad "blast-radius: incomplete report exit $st"
awk '
  /^in walk only:/ { section = "walk"; next }
  /^in report only:/ { section = "report"; next }
  section == "walk" && index($0, "Order.Validate") { priv = 1 }
  section == "walk" && index($0, "Checkout.Run") { ind = 1 }
  section == "walk" && index($0, "Order.Place") { mid = 1 }
  END { if (!(priv && ind && mid)) exit 1 }
' "$bout" || bad "blast-radius: incomplete report did not name the private and indirect callers"
rm -f "$bout"
sh scripts/blast-radius-callers.sh "$br/cycle.txt" A.A --expect "$br/cycle-callers.txt" >/dev/null || bad "blast-radius: cycle fixture failed"
st=0
sh scripts/blast-radius-callers.sh "$br/graph.txt" Missing.Sym >/dev/null 2>&1 || st=$?
[ "$st" -eq 1 ] || bad "blast-radius: unknown symbol exit $st"
st=0
sh scripts/blast-radius-callers.sh "$br/bad-edge.txt" Only.One >/dev/null 2>&1 || st=$?
[ "$st" -eq 2 ] || bad "blast-radius: bad edge exit $st"
st=0
sh scripts/blast-radius-callers.sh >/dev/null 2>&1 || st=$?
[ "$st" -eq 2 ] || bad "blast-radius: usage exit $st"

tf=docs/examples/test-failure-fixtures
class_cmp() {
  want=$1
  exp=$2
  shift 2
  st=0
  got=$(mktemp)
  sh scripts/classify-test-failures.sh "$@" >"$got" || st=$?
  [ "$st" -eq "$want" ] || bad "classify: $exp exit $st want $want"
  cmp -s "$got" "$exp" || bad "classify: $exp mismatch"
  rm -f "$got"
}
class_cmp 1 "$tf/mixed-expect.txt" "$tf/head-mixed.txt" "$tf/base.txt"
class_cmp 0 "$tf/env-expect.txt" "$tf/head-env.txt" "$tf/base.txt"
class_cmp 1 "$tf/new-expect.txt" "$tf/head-new.txt" "$tf/base.txt"
class_cmp 1 "$tf/detail-expect.txt" "$tf/head-detail.txt" "$tf/base-detail.txt"
class_cmp 1 "$tf/last-expect.txt" "$tf/head-last.txt" "$tf/base-detail.txt"
st=0
got=$(mktemp)
sh scripts/classify-test-failures.sh "$tf/head-new.txt" >"$got" || st=$?
[ "$st" -eq 1 ] || bad "classify: new without base exit $st"
cmp -s "$got" "$tf/new-expect.txt" || bad "classify: new without base mismatch"
if grep -q '^env-known' "$got"; then bad "classify: new without base labeled env-known"; fi
rm -f "$got"
st=0
got=$(mktemp)
sh scripts/classify-test-failures.sh "$tf/head-new.txt" "$tf/no-such-base.txt" >"$got" 2>/dev/null || st=$?
[ "$st" -eq 2 ] || bad "classify: missing base file exit $st"
if grep -q 'env-known' "$got"; then bad "classify: missing base file labeled env-known"; fi
rm -f "$got"
st=0
sh scripts/classify-test-failures.sh "$tf/malformed.txt" >/dev/null 2>&1 || st=$?
[ "$st" -eq 2 ] || bad "classify: malformed exit $st"
st=0
sh scripts/classify-test-failures.sh >/dev/null 2>&1 || st=$?
[ "$st" -eq 2 ] || bad "classify: usage exit $st"

rl=$(mktemp -d)
trap 'rm -rf "$rl"' EXIT
retro() {
  RETRO_ROOT=$rl RETRO_DATE=2026-11-05 sh scripts/retro-log.sh "$@"
}
tab=$(printf '\t')
mkdir -p "$rl/skills"
st=0
out=$(retro pending) || st=$?
[ "$st" -eq 0 ] || bad "retro-log: empty pending exit $st"
[ -z "$out" ] || bad "retro-log: empty pending printed"
st=0
retro begin --path 'a/../b' >/dev/null 2>&1 || st=$?
[ "$st" -eq 2 ] || bad "retro-log: dotdot path exit $st"
printf 'alpha-old\n' > "$rl/skills/a.md"
printf 'bravo-old\n' > "$rl/skills/b.md"
printf 'charlie-old\n' > "$rl/skills/c.md"
cp "$rl/skills/b.md" "$rl/bravo-old"
cp "$rl/skills/c.md" "$rl/charlie-old"
id1=$(retro begin --path skills/a.md)
printf 'alpha-new\n' > "$rl/skills/a.md"
retro seal "$id1" --error 'mistake a'
pend=$(retro pending)
printf '%s\n' "$pend" | grep -q "^${id1}${tab}2026-11-05${tab}pendiente${tab}" || bad "retro-log: pending row"
got=$(retro confirm "$id1")
grep -q "^${id1}${tab}2026-11-05${tab}confirmado${tab}" "$rl/.scratch/retro-log.tsv" || bad "retro-log: confirm state"
out=$(retro pending) || bad "retro-log: pending after confirm failed"
[ -z "$out" ] || bad "retro-log: confirm left a pendiente row"
before=$(cksum "$rl/.scratch/retro-log.tsv")
st=0
retro confirm "$id1" >/dev/null 2>&1 || st=$?
[ "$st" -ne 0 ] || bad "retro-log: second confirm exited 0"
after=$(cksum "$rl/.scratch/retro-log.tsv")
[ "$before" = "$after" ] || bad "retro-log: second confirm changed the log"
id2=$(retro begin --path skills/b.md)
printf 'bravo-new\n' > "$rl/skills/b.md"
retro seal "$id2" --error 'mistake b'
out=$(retro revert "$id2")
printf '%s\n' "$out" | grep -qx restored || bad "retro-log: revert did not print restored"
cmp -s "$rl/skills/b.md" "$rl/bravo-old" || bad "retro-log: revert bytes"
grep -q "^${id2}${tab}2026-11-05${tab}revertido${tab}" "$rl/.scratch/retro-log.tsv" || bad "retro-log: revert state"
id3=$(retro begin --path skills/c.md)
printf 'charlie-sealed\n' > "$rl/skills/c.md"
retro seal "$id3" --error 'mistake c'
printf 'charlie-later\n' > "$rl/skills/c.md"
cp "$rl/skills/c.md" "$rl/charlie-later"
st=0
out=$(retro revert "$id3") || st=$?
[ "$st" -eq 3 ] || bad "retro-log: dirty revert exit $st"
cmp -s "$rl/skills/c.md" "$rl/charlie-later" || bad "retro-log: dirty revert changed the file"
pend=$(retro pending)
printf '%s\n' "$pend" | grep -q "^${id3}${tab}2026-11-05${tab}pendiente${tab}" || bad "retro-log: dirty revert left the row"
out=$(retro revert --force "$id3")
cmp -s "$rl/skills/c.md" "$rl/charlie-old" || bad "retro-log: force bytes"
grep -q "^${id3}${tab}2026-11-05${tab}revertido${tab}" "$rl/.scratch/retro-log.tsv" || bad "retro-log: force state"
id4=$(retro begin --path skills/d.md)
printf 'added\n' > "$rl/skills/d.md"
retro seal "$id4" --error 'added file'
retro revert "$id4" >/dev/null
[ ! -e "$rl/skills/d.md" ] || bad "retro-log: revert left an added file"
printf 'echo-old\n' > "$rl/skills/e.md"
cp "$rl/skills/e.md" "$rl/echo-old"
id5=$(retro begin --path skills/e.md)
rm "$rl/skills/e.md"
retro seal "$id5" --error 'deleted file'
pend=$(retro pending)
printf '%s\n' "$pend" | grep -q "^${id5}${tab}2026-11-05${tab}pendiente${tab}missing${tab}0${tab}" || bad "retro-log: deleted file fingerprint"
retro revert "$id5" >/dev/null
cmp -s "$rl/skills/e.md" "$rl/echo-old" || bad "retro-log: revert did not restore a deleted file"
printf 'fox-old\n' > "$rl/skills/f.md"
id6=$(retro begin --path skills/f.md)
printf 'fox-new\n' > "$rl/skills/f.md"
cp "$rl/skills/f.md" "$rl/fox-new"
retro seal "$id6" --error 'lost snapshot'
rm -f "$rl/.scratch/retro-snapshots/$id6" "$rl/.scratch/retro-snapshots/$id6.missing"
out=$(retro revert "$id6")
printf '%s\n' "$out" | grep -qx marked-only || bad "retro-log: missing snapshot did not print marked-only"
cmp -s "$rl/skills/f.md" "$rl/fox-new" || bad "retro-log: missing snapshot changed the file"
grep -q "^${id6}${tab}2026-11-05${tab}revertido${tab}" "$rl/.scratch/retro-log.tsv" || bad "retro-log: missing snapshot state"
rm -rf "$rl"
trap - EXIT
sq=$(mktemp -d)
sqs=$PWD/scripts/sonar-diff-issues.sh
git -C "$sq" init -q -b main
printf 'a\nb\nc\n' > "$sq/A.cs"
printf 'x\n' > "$sq/Old.cs"
git -C "$sq" add -A
git -C "$sq" -c user.name=t -c user.email=t@t commit -q -m base
git -C "$sq" checkout -q -b feat
printf 'a\nB\nc\nd\n' > "$sq/A.cs"
git -C "$sq" -c user.name=t -c user.email=t@t commit -q -am change
cat > "$sq/issues.json" <<'JSON'
{"total":4,"issues":[
{"component":"local-k:A.cs","line":1,"severity":"MAJOR","rule":"r:old","message":"old line"},
{"component":"local-k:A.cs","line":2,"severity":"MAJOR","rule":"r:changed","message":"changed line"},
{"component":"local-k:A.cs","line":4,"severity":"MINOR","rule":"r:added","message":"added line"},
{"component":"local-k:Old.cs","line":1,"severity":"BLOCKER","rule":"r:untouched","message":"untouched file"},
{"component":"local-k:A.cs","severity":"INFO","rule":"r:file","message":"file level"}]}
JSON
printf '{"total":0,"issues":[]}\n' > "$sq/none.json"
st=0
sqout=$(cd "$sq" && sh "$sqs" main issues.json) || st=$?
[ "$st" -eq 1 ] || bad "sonar-diff: issues on changed lines exit $st"
[ "$(printf '%s\n' "$sqout" | wc -l | tr -d ' ')" = 2 ] || bad "sonar-diff: expected 2 lines, got: $sqout"
printf '%s\n' "$sqout" | grep -qF 'A.cs:2' || bad "sonar-diff: changed line missing"
printf '%s\n' "$sqout" | grep -qF 'A.cs:4' || bad "sonar-diff: added line missing"
case $sqout in *r:old*|*r:untouched*|*r:file*) bad "sonar-diff: reported an issue outside the diff" ;; esac
(cd "$sq" && sh "$sqs" main none.json >/dev/null) || bad "sonar-diff: no issues should exit 0"
st=0; (cd "$sq" && sh "$sqs" main >/dev/null 2>&1) || st=$?
[ "$st" -eq 2 ] || bad "sonar-diff: usage exit $st"
st=0; (cd "$sq" && sh "$sqs" nope issues.json >/dev/null 2>&1) || st=$?
[ "$st" -eq 2 ] || bad "sonar-diff: unknown base exit $st"
st=0; (cd "$sq" && SONAR_HOST_URL=http://127.0.0.1:9 sh "$sqs" main --fetch local-k >/dev/null 2>&1) || st=$?
[ "$st" -eq 3 ] || bad "sonar-diff: unreachable host should exit 3, got $st"
rm -rf "$sq"
grep -qF 'scripts/sonar-diff-issues.sh' docs/security-scan.md || bad "security-scan: missing sonar-diff-issues.sh"

rt=$(mktemp -d)
mkdir -p "$rt/pkg" "$rt/r/tests" "$rt/r/node_modules"
printf '{"values":[{"key":"baseUrl","value":"http://localhost:1"},{"key":"token","value":""},{"key":"auth","value":"{{token}}"}]}\n' > "$rt/pkg/env.json"
printf '{"item":[{"request":{"header":[{"key":"Authorization","value":"{{token}}"}]}}]}\n' > "$rt/pkg/coll.json"
sh scripts/check-export-package.sh "$rt/pkg" >/dev/null || bad "export-package: clean package should pass"
printf '{"values":[{"key":"password","value":"x1"}],"x":{"client_secret":"abc"}}\n' > "$rt/pkg/bad.json"
st=0; rtout=$(sh scripts/check-export-package.sh "$rt/pkg") || st=$?
[ "$st" -eq 1 ] || bad "export-package: secret values exit $st"
printf '%s\n' "$rtout" | grep -qF 'key=password' || bad "export-package: password value not named"
printf '%s\n' "$rtout" | grep -qF 'x.client_secret' || bad "export-package: nested secret not named"
st=0; sh scripts/check-export-package.sh "$rt/missing" >/dev/null 2>&1 || st=$?
[ "$st" -eq 2 ] || bad "export-package: usage exit $st"
printf 'var u = "https://api.example.com/x"; var l = "http://localhost:5000";\n' > "$rt/r/tests/AOkTest.cs"
printf 'var c = new HttpClient(); var b = Configuration["Base"];\n' > "$rt/r/tests/BRemoteTest.cs"
printf 'var u = "https://svc.internal.corp/api";\n' > "$rt/r/tests/CUrlTest.cs"
printf 'var u = "https://svc.internal.corp/api";\n' > "$rt/r/node_modules/DTest.cs"
st=0; rtout=$(sh scripts/check-remote-tests.sh "$rt/r") || st=$?
[ "$st" -eq 1 ] || bad "remote-tests: remote tests exit $st"
[ "$rtout" = "$(printf 'tests/BRemoteTest.cs\tconfigured-http\ntests/CUrlTest.cs\tremote-url')" ] || bad "remote-tests: wrong list: $rtout"
rm "$rt/r/tests/BRemoteTest.cs" "$rt/r/tests/CUrlTest.cs"
sh scripts/check-remote-tests.sh "$rt/r" >/dev/null || bad "remote-tests: local-only tests should pass"
printf '| campo `a` | obligatorio |\n| campo `b` | obligatorio, fuente: esquema nullable=NO |\nLa sección es obligatoria.\n```\ncampo x obligatorio\n```\n' > "$rt/s.md"
st=0; rtout=$(sh scripts/check-required-claims.sh "$rt/s.md") || st=$?
[ "$st" -eq 1 ] || bad "required-claims: unsourced claim exit $st"
[ "$rtout" = "fail required-claim line 1: cite the evidence with fuente: (schema, migration or query)" ] || bad "required-claims: wrong report: $rtout"
rm -rf "$rt"
grep -qF 'scripts/check-required-claims.sh' skills/to-techspec/SKILL.md || bad "to-techspec: must run check-required-claims.sh"

md=$(mktemp -d)
mkdir -p "$md/C/acme/r" "$md/C/beta/r" "$md/C/gamma" "$md/P/x"
printf 'clients_root = "%s/C"\n[clients.acme]\nroot = "%s/C/acme"\nmode = "plan-only"\n[clients.beta]\nroot = "%s/C/beta"\n' "$md" "$md" "$md" > "$md/c.toml"
mf() { env -u CLIENTS_ROOT -u ZSTACK_MODE ZSTACK_CLIENTS_TOML="$md/c.toml" sh scripts/mode-for.sh "$@" 2>/dev/null; }
mf "$md/C/acme/r" | grep -q '^mode: plan-only ' || bad "mode-for: client mode not read"
mf "$md/C/beta/r" | grep -q '^mode: ask-first ' || bad "mode-for: client without mode must be ask-first"
mf "$md/C/gamma" | grep -q '^mode: ask-first ' || bad "mode-for: clients root must be ask-first"
mf "$md/P/x" | grep -q '^mode: accept-edits ' || bad "mode-for: personal default must be accept-edits"
env -u CLIENTS_ROOT ZSTACK_MODE=plan-only ZSTACK_CLIENTS_TOML="$md/c.toml" sh scripts/mode-for.sh "$md/P/x" | grep -q '^mode: plan-only ' || bad "mode-for: stricter override ignored"
env -u CLIENTS_ROOT ZSTACK_MODE=accept-edits ZSTACK_CLIENTS_TOML="$md/c.toml" sh scripts/mode-for.sh "$md/C/beta/r" 2>/dev/null | grep -q '^mode: ask-first ' || bad "mode-for: looser override must not apply"
printf '[clients.bad]\nroot = "%s/C/acme"\nmode = "yolo"\n' "$md" > "$md/bad.toml"
st=0; env -u CLIENTS_ROOT ZSTACK_CLIENTS_TOML="$md/bad.toml" sh scripts/mode-for.sh "$md/C/acme/r" >/dev/null 2>&1 || st=$?
[ "$st" -eq 2 ] || bad "mode-for: unknown mode exit $st"
st=0; mf >/dev/null || st=$?
[ "$st" -eq 2 ] || bad "mode-for: usage exit $st"
rm -rf "$md"
grep -qF 'scripts/mode-for.sh' agents/opencode/zstack.md || bad "opencode zstack: must run mode-for.sh"
grep -qF 'mode = ' docs/examples/clients.toml.example || bad "clients.toml.example: mode missing"

[ -f docs/routing.md ] || bad "routing: docs/routing.md missing"
if grep -nE 'grok-|claude-|opus|gpt-|[0-9]{3} changed lines' docs/routing.md >/dev/null; then bad "routing: docs/routing.md copies a model slug or threshold"; fi
for s in 'docs/model-matrix.md' 'section 0' 'section 4' 'section 5'; do grep -qF "$s" docs/routing.md || bad "routing: missing pointer $s"; done
grep -qF 'follow section 0' agents/opencode/zstack.md || bad "opencode zstack: 2a must point at section 0"

revert_rate_commit() {
  when=$1
  shift
  GIT_AUTHOR_DATE="$when" GIT_COMMITTER_DATE="$when" \
    git -C "$rr" -c user.name=t -c user.email=t@t "$@"
}

rr=$(mktemp -d)
git init -q -b main "$rr"
st=0
sh scripts/revert-rate.sh -C "$rr" >"$rr/out" 2>"$rr/err" || st=$?
[ "$st" -eq 0 ] || bad "revert-rate: unborn exit $st"
[ ! -s "$rr/err" ] || bad "revert-rate: unborn wrote stderr"
printf '%s\n' 'changes 0, reverts 0, rate 0.0%' 'revert-rate changes=0 reverts=0 rate=0.0' >"$rr/want"
cmp -s "$rr/want" "$rr/out" || bad "revert-rate: unborn output: $(cat "$rr/out")"
rm -rf "$rr"

rr=$(mktemp -d)
git init -q -b main "$rr"
printf 'a\n' >"$rr/a"
git -C "$rr" add a
revert_rate_commit '2024-06-15 12:00:00 +0000' commit -q -m 'add alpha'
printf 'b\n' >"$rr/b"
git -C "$rr" add b
revert_rate_commit '2024-06-15 12:01:00 +0000' commit -q -m 'add beta'
printf 'c\n' >"$rr/c"
git -C "$rr" add c
revert_rate_commit '2024-06-15 12:02:00 +0000' commit -q -m 'add gamma'
revert_rate_commit '2024-06-15 12:03:00 +0000' revert --no-edit HEAD >/dev/null
rrsub=$(git -C "$rr" log -1 --format=%s)
[ "$rrsub" = 'Revert "add gamma"' ] || bad "revert-rate: fixture subject is $rrsub"
rrsha=$(git -C "$rr" rev-parse HEAD | cut -c1-7)
st=0
sh scripts/revert-rate.sh -C "$rr" --since 2020-01-01 >"$rr/out" 2>"$rr/err" || st=$?
[ "$st" -eq 0 ] || bad "revert-rate: one revert exit $st"
[ ! -s "$rr/err" ] || bad "revert-rate: one revert wrote stderr"
printf '%s\n' 'changes 4, reverts 1, rate 25.0%' "$rrsha $rrsub" 'revert-rate changes=4 reverts=1 rate=25.0' >"$rr/want"
cmp -s "$rr/want" "$rr/out" || bad "revert-rate: one revert output: $(cat "$rr/out")"
rm -rf "$rr"

rr=$(mktemp -d)
git init -q -b main "$rr"
printf 'x\n' >"$rr/f"
git -C "$rr" add f
revert_rate_commit '2024-06-15 12:00:00 +0000' commit -q -m 'drop the widget' -m 'This reverts commit abcdef0.'
rrsha=$(git -C "$rr" rev-parse HEAD | cut -c1-7)
st=0
sh scripts/revert-rate.sh -C "$rr" --since 2020-01-01 >"$rr/out" 2>"$rr/err" || st=$?
[ "$st" -eq 0 ] || bad "revert-rate: body marker exit $st"
[ ! -s "$rr/err" ] || bad "revert-rate: body marker wrote stderr"
printf '%s\n' 'changes 1, reverts 1, rate 100.0%' "$rrsha drop the widget" 'revert-rate changes=1 reverts=1 rate=100.0' >"$rr/want"
cmp -s "$rr/want" "$rr/out" || bad "revert-rate: body marker output: $(cat "$rr/out")"
if grep -F -q 'Revert "' "$rr/out"; then bad "revert-rate: body marker listed a Revert subject"; fi
rm -rf "$rr"

rr=$(mktemp -d)
git init -q -b main "$rr"
printf 'o\n' >"$rr/old"
git -C "$rr" add old
revert_rate_commit '2020-01-15 10:00:00 +0000' commit -q -m 'old base'
revert_rate_commit '2020-01-15 12:00:00 +0000' revert --no-edit HEAD >/dev/null
printf 'w\n' >"$rr/win"
git -C "$rr" add win
revert_rate_commit '2024-06-15 10:00:00 +0000' commit -q -m 'window feature'
revert_rate_commit '2024-06-15 12:00:00 +0000' revert --no-edit HEAD >/dev/null
printf 'l\n' >"$rr/later"
git -C "$rr" add later
revert_rate_commit '2026-06-15 10:00:00 +0000' commit -q -m 'later base'
revert_rate_commit '2026-06-15 12:00:00 +0000' revert --no-edit HEAD >/dev/null
rrfull=$(git -C "$rr" rev-parse HEAD~2)
rrsub=$(git -C "$rr" log -1 --format=%s "$rrfull")
[ "$rrsub" = 'Revert "window feature"' ] || bad "revert-rate: window fixture subject is $rrsub"
rrsha=$(printf '%.7s' "$rrfull")
st=0
sh scripts/revert-rate.sh -C "$rr" --since 2024-01-01 --until 2025-01-01 >"$rr/out" 2>"$rr/err" || st=$?
[ "$st" -eq 0 ] || bad "revert-rate: window exit $st"
[ ! -s "$rr/err" ] || bad "revert-rate: window wrote stderr"
printf '%s\n' 'changes 2, reverts 1, rate 50.0%' "$rrsha $rrsub" 'revert-rate changes=2 reverts=1 rate=50.0' >"$rr/want"
cmp -s "$rr/want" "$rr/out" || bad "revert-rate: window output: $(cat "$rr/out")"
if grep -F -q 'Revert "old base"' "$rr/out"; then bad "revert-rate: outside revert before the window"; fi
if grep -F -q 'Revert "later base"' "$rr/out"; then bad "revert-rate: outside revert after the window"; fi
rm -rf "$rr"

plain=$(mktemp -d)
st=0
sh scripts/revert-rate.sh -C "$plain/missing" >/dev/null 2>&1 || st=$?
[ "$st" -eq 2 ] || bad "revert-rate: missing path exit $st"
st=0
sh scripts/revert-rate.sh -C "$plain" >/dev/null 2>&1 || st=$?
[ "$st" -eq 2 ] || bad "revert-rate: not a repo exit $st"
rm -rf "$plain"
st=0
sh scripts/revert-rate.sh --not-a-flag >/dev/null 2>&1 || st=$?
[ "$st" -eq 2 ] || bad "revert-rate: unknown flag exit $st"

grep -qF 'scripts/revert-rate.sh' docs/scripts.md || bad "scripts.md: revert-rate missing"
grep -qF 'scripts/revert-rate.sh' skills/zretro/SKILL.md || bad "zretro: revert-rate missing"
if grep -q 'git fetch' scripts/revert-rate.sh; then bad "revert-rate: git fetch"; fi
if grep -F -q 'gh ' scripts/revert-rate.sh; then bad "revert-rate: gh"; fi

[ "$fail" -eq 0 ] && echo "check ok"
exit "$fail"
