#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

fail=0
scan_info='info security-scan: client repos stay on the developer machine; personal CI is in this repo (docs/security-scan.md)'

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  echo "usage: scripts/setup-check.sh"
  echo "$scan_info"
  exit 0
fi

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
for pair in zgrill:grill-me zgrill:grill-with-docs zspec:to-spec ztickets:to-tickets zpr:pr zretro:retro zwrite:writing-for-agents; do
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
for agent in zigl zninja zsensei; do
  p="$ROOT/.cursor/agents/$agent.md"
  target=$(readlink "$p" 2>/dev/null || true)
  if [ -L "$p" ] && [ -e "$p" ] && [ "$target" = "../../agents/$agent.md" ]; then
    echo "ok project agent $agent"
  else
    echo "missing project agent .cursor/agents/$agent.md (relative symlink to ../../agents/$agent.md; run scripts/link.sh)"
    fail=1
  fi
done
manifest="$HOME/.cursor/plugins/local/zstack-agents/.cursor-plugin/plugin.json"
if [ ! -f "$manifest" ]; then
  echo "missing plugin manifest $manifest (run scripts/link.sh)"
  fail=1
elif ! grep -q '"name": "zstack-agents"' "$manifest" || ! grep -q '"agents": "./agents/"' "$manifest"; then
  echo "fail plugin manifest $manifest (needs name zstack-agents and agents ./agents/)"
  fail=1
else
  echo "ok plugin manifest"
fi
for agent in zigl zninja zsensei; do
  dest="$HOME/.cursor/plugins/local/zstack-agents/agents/$agent.md"
  src="$ROOT/agents/$agent.md"
  if [ -L "$dest" ]; then
    echo "fail plugin agent $agent is a symlink (run scripts/link.sh)"
    fail=1
  elif [ ! -f "$dest" ]; then
    echo "missing plugin agent $dest (run scripts/link.sh)"
    fail=1
  elif ! cmp -s "$src" "$dest"; then
    echo "fail plugin agent $agent differs from agents/$agent.md"
    fail=1
  else
    echo "ok plugin agent $agent"
  fi
done
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

expand_home() {
  eh_p=$1
  case $eh_p in
    \~) eh_p=$HOME ;;
    \~/*) eh_p=$HOME/${eh_p#\~/} ;;
  esac
  while [ "$eh_p" != "/" ] && [ "${eh_p%/}" != "$eh_p" ]; do
    eh_p=${eh_p%/}
  done
  printf '%s\n' "$eh_p"
}

path_under() {
  pu_root=$1
  pu_path=$2
  [ -n "$pu_root" ] || return 1
  [ "$pu_path" = "$pu_root" ] && return 0
  [ "${pu_path#"$pu_root"/}" != "$pu_path" ]
}

if [ -n "${ZSTACK_CLIENTS_TOML:-}" ]; then
  cmap=$ZSTACK_CLIENTS_TOML
else
  cmap=$HOME/.config/zstack/clients.toml
fi
rules=$(mktemp)
trap 'rm -f "$rules" "$rules.all"' EXIT
: > "$rules"
map_root=
if [ -f "$cmap" ]; then
  awk '
    function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
    function strip_comment(s) { sub(/[[:space:]]+#.*$/, "", s); return s }
    function qval(s) {
      s = trim(s)
      if (s ~ /^".*"$/) return substr(s, 2, length(s) - 2)
      return ""
    }
    function emit_client() {
      if (active != 1 || root == "") return
      printf "C\034%s\034%s\034%s\034%s\034%s\n", root, has_email, email, has_domains, domains
    }
    BEGIN { active = 0; in_section = 0; root = ""; email = ""; domains = ""; has_email = 0; has_domains = 0 }
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    /^[[:space:]]*\[/ {
      emit_client()
      active = 0
      in_section = 1
      line = trim($0)
      if (line ~ /^\[clients\.[^]]+\]$/) {
        active = 1
        root = ""
        email = ""
        domains = ""
        has_email = 0
        has_domains = 0
      }
      next
    }
    {
      line = trim(strip_comment($0))
      if (line == "" || line !~ /=/) next
      key = line
      sub(/[[:space:]]*=.*/, "", key)
      key = trim(key)
      val = line
      sub(/^[^=]*=[[:space:]]*/, "", val)
      val = trim(val)
      if (in_section == 0 && key == "clients_root") {
        v = qval(val)
        if (v != "") printf "R\034%s\n", v
        next
      }
      if (active != 1) next
      if (key == "root" && val ~ /^".*"$/) root = qval(val)
      else if (key == "git_email" && val ~ /^".*"$/) { email = qval(val); has_email = 1 }
      else if (key == "git_email_domains" && val ~ /^\[/) {
        has_domains = 1
        domains = ""
        rest = val
        while (match(rest, /"[^"]*"/)) {
          q = substr(rest, RSTART + 1, RLENGTH - 2)
          if (domains == "") domains = q
          else domains = domains "," q
          rest = substr(rest, RSTART + RLENGTH)
        }
      }
    }
    END { emit_client() }
  ' "$cmap" > "$rules.all"
  fs=$(printf '\034')
  while IFS=$fs read -r kind f2 f3 f4 f5 f6; do
    case $kind in
      R) [ -n "$map_root" ] || map_root=$f2 ;;
      C) printf '%s%s%s%s%s%s%s%s%s\n' "$f2" "$fs" "$f3" "$fs" "$f4" "$fs" "$f5" "$fs" "$f6" >> "$rules" ;;
    esac
  done < "$rules.all"
  rm -f "$rules.all"
fi
if [ -n "${CLIENTS_ROOT:-}" ]; then
  croot=$(expand_home "$CLIENTS_ROOT")
elif [ -n "$map_root" ]; then
  croot=$(expand_home "$map_root")
else
  croot=$HOME/Clients
fi

apply_identity() {
  repo=$1
  email=$2
  bestlen=0
  bhas_email=0
  bemail=
  bhas_domains=0
  bdomains=
  while IFS=$(printf '\034') read -r rroot has_email gemail has_domains domains; do
    [ -n "$rroot" ] || continue
    expanded=$(expand_home "$rroot")
    path_under "$expanded" "$repo" || continue
    len=${#expanded}
    if [ "$len" -gt "$bestlen" ]; then
      bestlen=$len
      bhas_email=$has_email
      bemail=$gemail
      bhas_domains=$has_domains
      bdomains=$domains
    fi
  done < "$rules"
  [ "$bestlen" -gt 0 ] || return 0
  if [ "$bhas_email" = 1 ]; then
    if [ "$email" != "$bemail" ]; then
      echo "fail client identity: $repo uses '${email:-unset}', expected the client map git_email"
      fail=1
    fi
    return 0
  fi
  if [ "$bhas_domains" = 1 ]; then
    okd=0
    rest=$bdomains
    while [ -n "$rest" ]; do
      suf=${rest%%,*}
      case $rest in
        *,*) rest=${rest#*,} ;;
        *) rest= ;;
      esac
      if [ -n "$suf" ]; then
        case $email in
          *"$suf") okd=1 ;;
        esac
      fi
    done
    if [ "$okd" -eq 0 ]; then
      echo "warn client identity: $repo uses '${email:-unset}', expected a client map git_email_domains suffix"
    fi
  fi
}

ensure_local_excludes() {
  xf=$1
  mkdir -p "$(dirname "$xf")"
  if [ ! -f "$xf" ]; then
    : > "$xf"
  elif [ -s "$xf" ]; then
    nl=$(tail -c 1 "$xf" | wc -l | tr -d ' ')
    if [ "$nl" -eq 0 ]; then
      printf '\n' >> "$xf"
    fi
  fi
  missing=0
  for ent in .scratch/ .atl/; do
    if ! grep -qxF -- "$ent" "$xf"; then
      printf '%s\n' "$ent" >> "$xf"
    fi
    if ! grep -qxF -- "$ent" "$xf"; then
      missing=1
    fi
  done
  [ "$missing" -eq 0 ]
}

seen=""; n=0; m=0; k=0; pc=0; ex=0
if [ -d "$croot" ]; then
  for g in $(find "$croot" -maxdepth 6 -name .git 2>/dev/null | sort); do
    d=$(dirname "$g")
    common=$(git -C "$d" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || continue
    case " $seen " in *" $common "*) continue ;; esac
    seen="$seen $common"
    n=$((n + 1))
    xf=$(git -C "$d" rev-parse --path-format=absolute --git-path info/exclude)
    if ensure_local_excludes "$xf"; then ex=$((ex + 1)); fi
    email=$(git -C "$d" config user.email 2>/dev/null || true)
    apply_identity "$d" "$email"
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
  echo "info local-exclude: .scratch/ and .atl/ in info/exclude in $ex/$n client repos (setup-check writes them)"
fi
if [ -f "$HOME/.config/zstack/clients.toml" ]; then echo "ok client-kdb: map at ~/.config/zstack/clients.toml"
else echo "todo client-kdb: no ~/.config/zstack/clients.toml (copy docs/examples/clients.toml.example)"; fi
login=$(gh api user -q .login 2>/dev/null || true)
if [ -z "$login" ]; then echo "warn merge-guard: gh not logged in, cannot check the agent identity"
elif [ "$login" = Byevenes ]; then echo "todo merge-guard: gh acts as Byevenes (admin); only text stops the agent from merging"
else echo "ok merge-guard: gh acts as $login, not the repo admin"; fi
if command -v gitleaks >/dev/null 2>&1; then
  echo "ok gitleaks: present"
else
  echo "warn gitleaks: missing (install on the machine; see docs/security-scan.md)"
fi
echo "$scan_info"

exit "$fail"
