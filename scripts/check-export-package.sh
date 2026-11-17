#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
  echo "usage: scripts/check-export-package.sh <package-dir>" >&2
  exit 2
fi
command -v jq >/dev/null || { echo "fail: jq is required" >&2; exit 2; }

secret_keys='^(token|access_?token|refresh_?token|id_?token|jwt|password|pass|pwd|secret|client_?secret|api_?key|apikey|authorization|bearer|cookie|session)$'
bad=0
for f in "$1"/*.json; do
  [ -f "$f" ] || continue
  jq empty "$f" 2>/dev/null || { printf 'fail %s: not JSON\n' "${f##*/}"; bad=1; continue; }
  out=$(jq -r --arg re "$secret_keys" '
    [paths(scalars) as $p | {p: $p, v: getpath($p)}] as $all
    | ( $all[] | select((.p[-1] | tostring | ascii_downcase | test($re)) and (.v | tostring | length > 0) and ((.v | tostring | test("^\\{\\{[^}]+\\}\\}$")) | not)) | .p | map(tostring) | join(".") ),
      ( .. | objects | select(has("key") and has("value"))
        | select((.key | tostring | ascii_downcase | test($re)) and (.value | tostring | length > 0) and ((.value | tostring | test("^\\{\\{[^}]+\\}\\}$")) | not)) | "key=" + (.key | tostring) ),
      ( $all[] | select(.v | tostring | test("eyJ[A-Za-z0-9_-]{10,}\\.[A-Za-z0-9_-]{10,}\\.")) | .p | map(tostring) | join(".") )
    ' "$f" | LC_ALL=C sort -u)
  if [ -n "$out" ]; then
    printf '%s\n' "$out" | while IFS= read -r p; do printf 'fail %s: value set at %s\n' "${f##*/}" "$p"; done
    bad=1
  fi
done
if command -v gitleaks >/dev/null; then
  gitleaks dir "$1" --redact --no-banner >/dev/null 2>&1 || { echo "fail: gitleaks found a secret in the package"; bad=1; }
fi
exit "$bad"
