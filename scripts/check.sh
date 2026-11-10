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

for f in skills/zstack/SKILL.md agents/opencode/zstack.md; do
  grep -q -- '--force' "$f" || bad "$f: client rule about --force missing"
  grep -q 'Client slice commits' "$f" || bad "$f: client slice commit rule missing"
done

grep -q 'technology-agnostic' skills/zstack/SKILL.md || bad "zstack: client checks must be detected agnostically"
grep -q 'Never invent checks' skills/zstack/SKILL.md || bad "zstack: client rule must forbid invented checks"
grep -q 'Pre-push gate' skills/zstack/SKILL.md || bad "zstack: client rule must define the pre-push gate"
grep -qF 'docs/security-scan.md' skills/zstack/SKILL.md || bad "zstack: pre-push must point at docs/security-scan.md"
grep -qF 'gitleaks git --log-opts' skills/zstack/SKILL.md || bad "zstack: pre-push must use branch-vs-base gitleaks"
grep -qF 'SonarQube for IDE' skills/zstack/SKILL.md || bad "zstack: pre-push must mention SonarQube for IDE"
grep -qF 'client pipeline remains the source of truth' skills/zstack/SKILL.md || bad "zstack: pre-push must keep the client pipeline as truth"
grep -q 'push_checks' docs/examples/clients.toml.example || bad "clients.toml.example: push_checks missing"
grep -q 'Recovery case' skills/zstack/SKILL.md || bad "zstack: client commit rule must define the mixed-slices recovery case"
grep -q '### Slice loop' skills/zstack/SKILL.md || bad "zstack: slice loop missing"
grep -q 'A recovery plan does not replace that new session' skills/zstack/SKILL.md || bad "zstack: recovery must not replace a new session per slice"
grep -q 'The next ticket is not started here' skills/zstack/SKILL.md || bad "zstack: slice close must require a clean session"
grep -q 'scripts/check-commit-order.sh' skills/zstack/SKILL.md || bad "zstack: commit-order gate missing"
grep -q 'scripts/check-commit-order.sh' docs/scripts.md || bad "scripts.md: commit-order gate missing"
grep -q 'scripts/blast-radius-callers.sh' skills/zstack/SKILL.md || bad "zstack: blast-radius caller gate missing"
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
zn_front=$(awk 'BEGIN{n=0} /^---$/{n++; if (n==2) exit; next} n==1 {print}' agents/zninja.md)
if printf '%s\n' "$zn_front" | grep -q '^model:'; then bad "zninja: model must stay unset so the subagent inherits"; fi
if printf '%s\n' "$zn_front" | grep -q -- '-fast'; then bad "zninja: must not set a -fast model"; fi
zs_front=$(awk 'BEGIN{n=0} /^---$/{n++; if (n==2) exit; next} n==1 {print}' agents/zsensei.md)
if ! printf '%s\n' "$zs_front" | grep -qx 'model: claude-opus-5-5-medium'; then bad "zsensei: model must be claude-opus-5-5-medium"; fi
if ! printf '%s\n' "$zs_front" | grep -qx 'readonly: true'; then bad "zsensei: readonly must be true"; fi
grep -qF 'Every Task call to zsensei passes model: claude-opus-5-5-medium.' skills/zstack/SKILL.md || bad "zstack: zsensei Task model sentence missing"
grep -q 'issue #58' skills/zstack/SKILL.md || bad "zstack: inline fallback must cite issue #58"
grep -qF '.cursor/agents/' skills/zstack/SKILL.md || bad "zstack: inline fallback must name .cursor/agents/"
check_project_agents
grep -q 'scope changed' skills/zstack/SKILL.md || bad "zstack: client commit rule must stop on a scope change"
grep -q 'git add -A' skills/zstack/SKILL.md || bad "zstack: client commit rule must forbid git add -A"
grep -q 'never use `--no-verify`' skills/zstack/SKILL.md || bad "zstack: client commit rule must forbid --no-verify"

zs=skills/zstack/SKILL.md
grep -qF '### Inline without Cursor' "$zs" || bad "zstack: Inline without Cursor heading missing"
grep -qF 'git push --dry-run' "$zs" || bad "zstack: push dry-run missing"
grep -qF 'before coding starts' "$zs" || bad "zstack: dry-run must run before coding starts"
grep -qF 'only the diff' "$zs" || bad "zstack: reviewer must receive only the diff"
grep -qF 'independent (no Cursor)' "$zs" || bad "zstack: independent reviewer missing"
grep -qF 'independent (no Cursor)' agents/opencode/zstack.md || bad "opencode zstack: independent reviewer missing"
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
grep -qF 'pendiente' skills/zretro/SKILL.md || bad "zretro: pendiente missing"
grep -qF 'confirmado' skills/zretro/SKILL.md || bad "zretro: confirmado missing"
grep -qF 'revertido' skills/zretro/SKILL.md || bad "zretro: revertido missing"
grep -qF 'Review every pendiente in the retro log before proposing a new change.' skills/zretro/SKILL.md || bad "zretro: pending review sentence missing"
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

grep -qF 'to-techspec 7ce3d36805ad176911be8262a6e2dd3429cfd47b' skills/versions || bad "skills/versions: to-techspec pin missing"
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
for p in .cursor/skills/zstack .cursor/skills/zgrill .cursor/skills/zpr .cursor/skills/blast-radius .cursor/rules/zstack.mdc .cursor/agents/zninja.md .config/opencode/skills/zstack .config/opencode/skills/blast-radius .config/opencode/zstack.md .config/opencode/agents/zstack.md; do
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
pin=7ce3d36805ad176911be8262a6e2dd3429cfd47b
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
if grep -q 'scripts/check-repo-paths.sh' "$h/.cursor/skills/to-techspec/SKILL.md"; then bad "link.sh: override pin still has the checkout marker"; fi
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
printf '%s\n' '## Resumen' nada '```claims' ninguno '```' '## Hallazgos' dos '## Incertidumbres' tres '## Fuentes' cuatro 'ramas-fuera-de-base: ninguna' > "$d/nobr.md"
if sh "$root/scripts/check-unmerged-branches.sh" --repo "$er/r" --draft "$d/nobr.md" >/dev/null 2>"$err"; then bad "branches: unnamed other should fail"; fi
grep -qF 'fail branches: other not named' "$err" || bad "branches: unnamed stderr"
printf '%s\n' '## Resumen' 'rama other' '```claims' ninguno '```' '## Hallazgos' dos '## Incertidumbres' tres '## Fuentes' cuatro > "$d/named.md"
sh "$root/scripts/check-unmerged-branches.sh" --repo "$er/r" --draft "$d/named.md" >/dev/null || bad "branches: named other should pass"
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
grep -q 'como UTC' "$lesson" || bad "timezone lesson: missing UTC default"
grep -q 'Normaliza' "$lesson" || bad "timezone lesson: missing normalize-before-compare"
grep -q 'TZ' "$lesson" || bad "timezone lesson: missing TZ"

for f in scripts/check.sh scripts/link.sh scripts/setup-check.sh scripts/check-delivery-note.sh scripts/check-repo-paths.sh scripts/check-commit-order.sh scripts/blast-radius-callers.sh scripts/classify-test-failures.sh scripts/retro-log.sh scripts/check-prestage-kdb.sh scripts/prestage-handoff.sh scripts/check-topic-repos.sh scripts/check-client-surface.sh scripts/evidence-probe.sh scripts/check-claims.sh scripts/check-unmerged-branches.sh; do
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
[ "$id1" = 1 ] || bad "retro-log: first id is $id1"
printf 'alpha-new\n' > "$rl/skills/a.md"
retro seal "$id1" --error 'mistake a'
pend=$(retro pending)
printf '%s\n' "$pend" | grep -q "^${id1}${tab}2026-11-05${tab}pendiente${tab}" || bad "retro-log: pending row"
printf '%s\n' "$pend" | grep -q 'mistake a' || bad "retro-log: pending error"
got=$(retro confirm "$id1")
[ "$got" = "$id1" ] || bad "retro-log: confirm printed $got"
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
printf '%s\n' "$out" | grep -qx "$id2" || bad "retro-log: revert did not print the id"
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
[ "$out" = dirty ] || bad "retro-log: dirty revert printed $out"
cmp -s "$rl/skills/c.md" "$rl/charlie-later" || bad "retro-log: dirty revert changed the file"
pend=$(retro pending)
printf '%s\n' "$pend" | grep -q "^${id3}${tab}2026-11-05${tab}pendiente${tab}" || bad "retro-log: dirty revert left the row"
out=$(retro revert --force "$id3")
printf '%s\n' "$out" | grep -qx restored || bad "retro-log: force did not restore"
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

rn=$(mktemp -d)
trap 'rm -rf "$rn"' EXIT
runlog() {
  RUN_ROOT=$rn sh scripts/run-log.sh "$@"
}
tab=$(printf '\t')
task1=task-alpha
model1=model-alpha
checks1=checks-alpha
result1=result-alpha
cost1=cost-alpha
task2=task-beta
model2=model-beta
checks2=checks-beta
result2=result-beta
cost2=cost-beta
st=0
out=$(runlog show) || st=$?
[ "$st" -eq 0 ] || bad "run-log: empty show exit $st"
[ -z "$out" ] || bad "run-log: empty show printed"
st=0
runlog append --task "bad${tab}task" --model "$model1" --checks "$checks1" --result "$result1" --cost "$cost1" >/dev/null 2>&1 || st=$?
[ "$st" -eq 2 ] || bad "run-log: tab in task exit $st"
[ ! -e "$rn/.scratch/run-log.tsv" ] || bad "run-log: tab in task created the log"
id1=$(runlog append --task "$task1" --model "$model1" --checks "$checks1" --result "$result1" --cost "$cost1")
[ "$id1" = 1 ] || bad "run-log: first id is $id1"
cp "$rn/.scratch/run-log.tsv" "$rn/saved.tsv"
id2=$(runlog append --task "$task2" --model "$model2" --checks "$checks2" --result "$result2" --cost "$cost2")
[ "$id2" = 2 ] || bad "run-log: second id is $id2"
len=$(wc -c < "$rn/saved.tsv" | tr -d ' ')
dd if="$rn/.scratch/run-log.tsv" of="$rn/prefix.tsv" bs=1 count="$len" status=none
cmp -s "$rn/saved.tsv" "$rn/prefix.tsv" || bad "run-log: append rewrote an earlier row"
first=$(awk 'NR == 1 { print; exit }' "$rn/.scratch/run-log.tsv")
savedline=$(awk 'NR == 1 { print; exit }' "$rn/saved.tsv")
[ "$first" = "$savedline" ] || bad "run-log: first line is not the first row"
row=$(runlog show 1)
[ "$row" = "1${tab}${task1}${tab}${model1}${tab}${checks1}${tab}${result1}${tab}${cost1}" ] || bad "run-log: show 1 row"
got_model=$(printf '%s\n' "$row" | awk -F '\t' '{ print $3 }')
got_checks=$(printf '%s\n' "$row" | awk -F '\t' '{ print $4 }')
got_cost=$(printf '%s\n' "$row" | awk -F '\t' '{ print $6 }')
[ "$got_model" = "$model1" ] || bad "run-log: show 1 model is $got_model"
[ "$got_checks" = "$checks1" ] || bad "run-log: show 1 checks is $got_checks"
[ "$got_cost" = "$cost1" ] || bad "run-log: show 1 cost is $got_cost"
case $row in
  *"$model2"*) bad "run-log: show 1 contains the second model" ;;
esac
both=$(runlog show)
printf '%s\n' "$both" > "$rn/shown.tsv"
cmp -s "$rn/.scratch/run-log.tsv" "$rn/shown.tsv" || bad "run-log: show did not print both rows"
st=0
out=$(runlog show 9 2>/dev/null) || st=$?
[ "$st" -eq 1 ] || bad "run-log: unknown id exit $st"
[ -z "$out" ] || bad "run-log: unknown id printed"
st=0
out=$(sh scripts/run-log.sh 2>/dev/null) || st=$?
[ "$st" -eq 2 ] || bad "run-log: usage exit $st"
[ -z "$out" ] || bad "run-log: usage wrote to stdout"
rm -rf "$rn"
trap - EXIT

[ "$fail" -eq 0 ] && echo "check ok"
exit "$fail"
