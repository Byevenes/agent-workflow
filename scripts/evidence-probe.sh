#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

usage() {
  printf '%s\n' 'usage: scripts/evidence-probe.sh --repo <dir> --token <text>' >&2
  exit 2
}

repo=
token=
while [ "$#" -gt 0 ]; do
  case $1 in
    --repo|--token)
      if [ "$#" -lt 2 ]; then
        usage
      fi
      if [ "$1" = --repo ]; then
        if [ -n "$repo" ]; then usage; fi
        repo=$2
      else
        if [ -n "$token" ]; then usage; fi
        token=$2
      fi
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done
if [ -z "$repo" ] || [ -z "$token" ]; then
  usage
fi
if [ ! -d "$repo" ]; then
  printf '%s\n' "fail evidence: $repo is not a directory" >&2
  exit 1
fi

found_path=
while IFS= read -r f || [ -n "$f" ]; do
  [ -n "$f" ] || continue
  if grep -F -q -- "$token" "$f"; then
    found_path=$f
    break
  fi
done <<EOF
$(find "$repo" \( -name .git -o -path '*/.git/*' \) -prune -o -type f \( -name '*values*.yaml' -o -name '*values*.yml' -o -name 'Chart.yaml' -o -path '*/deploy/*' -o -path '*/helm/*' \) -print)
EOF
if [ -n "$found_path" ]; then
  printf '%s\n' "config: found ${found_path#"$repo"/}"
else
  printf '%s\n' 'config: absent'
fi
subj=$(git -C "$repo" log -S"$token" --format='%s' -n 1 2>/dev/null || true)
if [ -n "$subj" ]; then
  printf '%s\n' "history: found $subj"
else
  printf '%s\n' 'history: absent'
fi
