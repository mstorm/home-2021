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

# Ensure generic runtime dirs exist
mkdir -p "$ROOT/run"/{tmp,lock,logs,state}
mkdir -p "$ROOT/lib/traefik"

# Create acme.json if it doesn't exist
if [[ ! -f "$ROOT/lib/traefik/acme.json" ]]; then
  touch "$ROOT/lib/traefik/acme.json"
  chmod 600 "$ROOT/lib/traefik/acme.json"
fi

echo "init ok: edge/traefik"

