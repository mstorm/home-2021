#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-.}"
# Convert to absolute path
ROOT="$(cd "$ROOT" && pwd)"

# Load environment variables
if [[ -f "$ROOT/etc/global.env" ]]; then
  set -a
  source "$ROOT/etc/global.env"
  set +a
fi

if [[ -f "$ROOT/etc/srv/edge.caddy.env" ]]; then
  set -a
  source "$ROOT/etc/srv/edge.caddy.env"
  set +a
fi

# Ensure generic runtime dirs exist
mkdir -p "$ROOT/run"/{tmp,lock,logs,state}
mkdir -p "$ROOT/lib/caddy"/{config,data}

echo "init ok: edge/caddy"

