#!/bin/sh
set -eu
exec "$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)/skills/zstack/scripts/route-audit.sh" "$@"
