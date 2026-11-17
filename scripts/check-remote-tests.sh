#!/bin/sh
set -eu

if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
  echo "usage: scripts/check-remote-tests.sh <repo-root>" >&2
  exit 2
fi

local_re='(localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\]|[A-Za-z0-9.-]*example\.(com|org|net)|[A-Za-z0-9.-]+\.(test|invalid|localhost))'
client_re='(HttpClient|RestClient|WebClient|fetch\(|axios|requests\.(get|post|put|delete)|urllib|http\.Get|reqwest)'
config_re='(GetSection|Configuration\[|IConfiguration|appsettings|process\.env|os\.environ|getenv|System\.getenv)'

hit=0
find "$1" -type d \( -name .git -o -name node_modules -o -name bin -o -name obj -o -name dist -o -name .scratch \) -prune -o -type f \( \
    -name '*Test*.cs' -o -name '*Tests.cs' -o -name '*.test.ts' -o -name '*.test.js' -o -name '*.spec.ts' -o -name '*.spec.js' \
    -o -name 'test_*.py' -o -name '*_test.py' -o -name '*_test.go' -o -name '*Test.java' -o -name '*IT.java' \) -print |
  LC_ALL=C sort > "${TMPDIR:-/tmp}/remote-tests.$$"
while IFS= read -r f; do
  rel=${f#"$1"/}
  if grep -Eo 'https?://[^"'"'"' )]+' "$f" | grep -Evq "^https?://$local_re"; then
    printf '%s\tremote-url\n' "$rel"; hit=1
  elif grep -Eq "$client_re" "$f" && grep -Eq "$config_re" "$f"; then
    printf '%s\tconfigured-http\n' "$rel"; hit=1
  fi
done < "${TMPDIR:-/tmp}/remote-tests.$$"
rm -f "${TMPDIR:-/tmp}/remote-tests.$$"
exit "$hit"
