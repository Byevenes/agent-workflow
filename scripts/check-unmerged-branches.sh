#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

usage() {
  printf '%s\n' 'usage: scripts/check-unmerged-branches.sh --repo <dir> --draft <file>' >&2
  exit 2
}

repo=
draft=
while [ "$#" -gt 0 ]; do
  case $1 in
    --repo|--draft)
      if [ "$#" -lt 2 ]; then usage; fi
      if [ "$1" = --repo ]; then
        if [ -n "$repo" ]; then usage; fi
        repo=$2
      else
        if [ -n "$draft" ]; then usage; fi
        draft=$2
      fi
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done
if [ -z "$repo" ] || [ -z "$draft" ]; then
  usage
fi
if [ ! -d "$repo" ]; then
  printf '%s\n' "fail branches: $repo is not a directory" >&2
  exit 1
fi
if [ ! -f "$draft" ]; then
  printf '%s\n' "fail branches: $draft is not a file" >&2
  exit 1
fi
if ! git -C "$repo" rev-parse --verify main >/dev/null 2>&1; then
  printf '%s\n' 'fail branches: base main is missing' >&2
  exit 1
fi

unmerged=$(git -C "$repo" branch --format='%(refname:short)' --no-merged main)
if [ -z "$unmerged" ]; then
  if ! grep -qxF 'ramas-fuera-de-base: ninguna' "$draft"; then
    printf '%s\n' 'fail branches: want ramas-fuera-de-base: ninguna' >&2
    exit 1
  fi
  printf '%s\n' "ok branches: $draft"
  exit 0
fi
while IFS= read -r br || [ -n "$br" ]; do
  [ -n "$br" ] || continue
  if ! grep -F -q -- "$br" "$draft"; then
    printf '%s\n' "fail branches: $br not named" >&2
    exit 1
  fi
done <<EOF
$unmerged
EOF
printf '%s\n' "ok branches: $draft"
