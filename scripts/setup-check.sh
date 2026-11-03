#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

fail=0

need() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "ok command $1"
  else
    echo "missing command $1"
    fail=1
  fi
}

need gh
need opencode
need cursor-agent

ROOT=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)

check_link() {
  path=$1
  if [ -L "$path" ] || [ -e "$path" ]; then
    echo "ok path $path"
  else
    echo "missing path $path"
    fail=1
  fi
}

if [ "$(git -C "$ROOT" config --bool core.bare 2>/dev/null || true)" = true ]; then echo "fail agent-workflow: core.bare=true (a fixture wrote to this repo; git -C $ROOT config core.bare false)"; fail=1; fi
check_link "$HOME/.cursor/skills/zstack"
check_link "$HOME/.cursor/skills/route-work"
for pair in zgrill:grill-me zgrill:grill-with-docs zspec:to-spec ztickets:to-tickets zpr:pr zretro:retro; do
  w=${pair%%:*}
  m=${pair#*:}
  if [ ! -f "$HOME/.cursor/skills/$w/SKILL.md" ]; then echo "missing wrapper $w (run scripts/link.sh)"; fail=1
  elif [ ! -f "$HOME/.agents/skills/$m/SKILL.md" ]; then echo "warn $m: Matt skill missing; $w will ask for /$m by hand"
  else echo "ok $m: invoked via $w"; fi
done
f="$HOME/.cursor/skills/tdd/SKILL.md"
if [ ! -f "$f" ]; then echo "missing skill tdd"
elif grep -q '^disable-model-invocation: *true' "$f"; then echo "todo tdd: remove disable-model-invocation"
else echo "ok tdd model-invocable"; fi
check_link "$HOME/.config/opencode/skills/zstack"
check_link "$HOME/.cursor/agents/zigl.md"
check_link "$HOME/.config/opencode/agents/zigl.md"
check_link "$HOME/.cursor/plugins/cache/cursor-public/pstack"
check_link "$ROOT/skills/zstack/SKILL.md"
check_link "$HOME/.cursor/rules/zstack.mdc"
check_link "$HOME/.cursor/agents/zninja.md"
check_link "$HOME/.cursor/agents/zsensei.md"
check_link "$HOME/.config/opencode/agents/zsensei.md"
check_link "$HOME/.config/opencode/agents/zstack.md"
for a in zstack zninja zsensei; do
  f="$HOME/.config/opencode/agents/$a.md"
  if [ -f "$f" ] && grep -Eq '^model: *"?opencode/' "$f"; then echo "fail opencode $a: model opencode/* (Zen); client code must not go to Zen"; fail=1
  elif [ -f "$f" ]; then echo "ok opencode $a: no opencode/* model"; fi
done
for s in to-analysis to-questionnaire to-techspec; do
  for d in "$HOME/.cursor/skills" "$HOME/.config/opencode/skills"; do
    if [ -f "$d/$s/SKILL.md" ]; then echo "ok pre-stage $s in $d"; else echo "warn pre-stage $s missing in $d (zstack section 0 stops and tells Brayan)"; fi
  done
done
if grep -q '"default_agent": "zstack"' "$HOME/.config/opencode/opencode.json" 2>/dev/null; then echo "ok opencode default_agent zstack"; else echo "todo opencode: set \"default_agent\": \"zstack\""; fi
if grep -q "zstack.md" "$HOME/.config/opencode/opencode.json" 2>/dev/null; then echo "ok opencode instructions zstack"; else echo "todo opencode: add ~/.config/opencode/zstack.md to \"instructions\" in opencode.json"; fi

for v in GITHUB_PERSONAL_ACCESS_TOKEN GITLAB_PERSONAL_ACCESS_TOKEN POSTGRES_URL; do
  if [ -n "$(printenv "$v" || true)" ]; then echo "ok env $v"
  else echo "optional env $v (unset; not needed, keeps client data out of OpenCode)"; fi
done

croot=${CLIENTS_ROOT:-$HOME/Sites/tinet/Clients}
seen=""; n=0; m=0; k=0; pc=0; ex=0
if [ -d "$croot" ]; then
  for g in $(find "$croot" -maxdepth 6 -name .git 2>/dev/null | sort); do
    d=$(dirname "$g")
    common=$(git -C "$d" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || continue
    case " $seen " in *" $common "*) continue ;; esac
    seen="$seen $common"
    n=$((n + 1))
    xf=$(git -C "$d" rev-parse --path-format=absolute --git-path info/exclude)
    if [ -f "$xf" ] && grep -qx '\.scratch/\{0,1\}' "$xf"; then ex=$((ex + 1)); fi
    email=$(git -C "$d" config user.email 2>/dev/null || true)
    case $d in
      "$croot"/confuturo/*)
        if [ "$email" != brayan.yevenes@tinet.cl ]; then echo "fail client identity: $d uses '${email:-unset}', Confuturo needs brayan.yevenes@tinet.cl (includeIf, see docs/architecture.md)"; fail=1; fi ;;
      "$croot"/tenpo/*)
        case $email in *@tenpo.cl|*@tinet.cl) ;; *) echo "warn client identity: $d uses '${email:-unset}', expected @tenpo.cl or @tinet.cl" ;; esac ;;
      *)
        case $email in *@tinet.cl) ;; *) echo "warn client identity: $d uses '${email:-unset}', expected @tinet.cl" ;; esac ;;
    esac
    if [ -n "$(git -C "$d" config --get core.hooksPath)" ]; then k=$((k + 1)); continue; fi
    hp=$(git -C "$d" rev-parse --path-format=absolute --git-path hooks)/pre-push
    if [ -f "$hp" ] && grep -q client-guard "$hp"; then m=$((m + 1)); fi
    hc=${hp%pre-push}pre-commit
    if [ -f "$hc" ] && grep -q client-guard "$hc"; then pc=$((pc + 1)); fi
  done
fi
line="client-guard: pre-push in $m/$n client repos, skipped (husky) $k"
if [ "$n" -eq 0 ]; then echo "ok client-guard: no client repos found"
elif [ $((m + k)) -eq "$n" ]; then echo "ok $line"
else echo "todo $line (Brayan installs: see docs/architecture.md)"; fi
if [ "$n" -gt 0 ]; then
  echo "info client-guard pre-commit: $pc/$n client repos (Brayan installs: see docs/architecture.md)"
  echo "info scratch-exclude: .scratch/ in info/exclude in $ex/$n client repos (zstack adds it per worktree)"
fi
login=$(gh api user -q .login 2>/dev/null || true)
if [ -z "$login" ]; then echo "warn merge-guard: gh not logged in, cannot check the agent identity"
elif [ "$login" = Byevenes ]; then echo "todo merge-guard: gh acts as Byevenes (admin); only text stops the agent from merging"
else echo "ok merge-guard: gh acts as $login, not the repo admin"; fi

exit "$fail"
