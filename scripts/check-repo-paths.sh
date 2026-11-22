#!/bin/sh
set -eu
exec "$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)/skills/zspec/scripts/check-repo-paths.sh" "$@"
