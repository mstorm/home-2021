#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"
# Convert to absolute path
ROOT="$(cd "$ROOT" && pwd)"
UNIT="${2:-}"
export OPS_ROOT="$ROOT"

if [[ -z "$UNIT" ]]; then
  echo "Usage: validate.sh <root> <unit-path-under-srv>"
  exit 2
fi

cd "$ROOT/srv/$UNIT"

if [[ ! -f compose.yml ]]; then
  echo "compose.yml not found in $ROOT/srv/$UNIT"
  exit 1
fi

docker compose -f compose.yml config >/dev/null
echo "OK: $UNIT"
