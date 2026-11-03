#!/bin/sh
set -eu

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
if grep -q '"default_agent": "zstack"' "$HOME/.config/opencode/opencode.json" 2>/dev/null; then echo "ok opencode default_agent zstack"; else echo "todo opencode: set \"default_agent\": \"zstack\""; fi
if grep -q "zstack.md" "$HOME/.config/opencode/opencode.json" 2>/dev/null; then echo "ok opencode instructions zstack"; else echo "todo opencode: add ~/.config/opencode/zstack.md to \"instructions\" in opencode.json"; fi

for v in GITHUB_PERSONAL_ACCESS_TOKEN GITLAB_PERSONAL_ACCESS_TOKEN POSTGRES_URL; do
  if [ -n "$(printenv "$v" || true)" ]; then echo "ok env $v"
  else echo "optional env $v (unset; not needed, keeps client data out of OpenCode)"; fi
done

croot=${CLIENTS_ROOT:-$HOME/Sites/tinet/Clients}
seen=""; n=0; m=0; k=0
if [ -d "$croot" ]; then
  for g in $(find "$croot" -maxdepth 6 -name .git 2>/dev/null | sort); do
    d=$(dirname "$g")
    common=$(git -C "$d" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || continue
    case " $seen " in *" $common "*) continue ;; esac
    seen="$seen $common"
    n=$((n + 1))
    if [ -n "$(git -C "$d" config --get core.hooksPath)" ]; then k=$((k + 1)); continue; fi
    hp=$(git -C "$d" rev-parse --path-format=absolute --git-path hooks)/pre-push
    if [ -f "$hp" ] && grep -q client-guard "$hp"; then m=$((m + 1)); fi
  done
fi
line="client-guard: pre-push in $m/$n client repos, skipped (husky) $k"
if [ "$n" -eq 0 ]; then echo "ok client-guard: no client repos found"
elif [ $((m + k)) -eq "$n" ]; then echo "ok $line"
else echo "todo $line (Brayan installs: see docs/architecture.md)"; fi
login=$(gh api user -q .login 2>/dev/null || true)
if [ -z "$login" ]; then echo "warn merge-guard: gh not logged in, cannot check the agent identity"
elif [ "$login" = Byevenes ]; then echo "todo merge-guard: gh acts as Byevenes (admin); only text stops the agent from merging"
else echo "ok merge-guard: gh acts as $login, not the repo admin"; fi

exit "$fail"
