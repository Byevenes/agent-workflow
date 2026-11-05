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

usage() {
  echo "usage: scripts/check-commit-order.sh <base> -- <command> [args...]" >&2
  exit 2
}

[ "$#" -ge 1 ] || usage
base=$1
shift
[ "$#" -ge 1 ] && [ "$1" = "--" ] || usage
shift
[ "$#" -ge 1 ] || usage

git rev-parse --is-inside-work-tree >/dev/null
git rev-parse --verify "${base}^{commit}" >/dev/null

parent=$(mktemp -d)
hooks=$(mktemp -d)
wt=
trap 'if [ -n "$wt" ]; then git -c core.hooksPath="$hooks" worktree remove --force "$wt" >/dev/null 2>&1 || true; fi; git worktree prune >/dev/null 2>&1 || true; rm -rf "$parent" "$hooks"' EXIT

revs=$(git rev-list --reverse "${base}..HEAD")
if [ -z "$revs" ]; then
  echo "check-commit-order: no commits in ${base}..HEAD"
  exit 0
fi

fail=0
while read -r rev; do
  [ -n "$rev" ] || continue
  wt="${parent}/${rev}"
  git -c core.hooksPath="$hooks" worktree add --detach --quiet "$wt" "$rev"
  set +e
  (
    cd "$wt" || exit 1
    unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX
    unset GIT_CONFIG_COUNT GIT_CONFIG_PARAMETERS
    "$@"
  )
  status=$?
  set -e
  git -c core.hooksPath="$hooks" worktree remove --force "$wt"
  wt=
  if [ "$status" -ne 0 ]; then
    echo "check-commit-order: FAIL $rev (exit $status)" >&2
    fail=1
    break
  fi
done <<EOF
$revs
EOF

exit "$fail"
