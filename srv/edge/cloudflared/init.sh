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
mkdir -p "$ROOT/lib/cloudflared"

# Process template files and generate actual YAML files
DNS_NAME="${DNS_NAME:-home.internal}"
export DNS_NAME

# Generate YAML file from template
if [[ -f "$ROOT/srv/edge/cloudflared/config/config.yml.template" ]]; then
  sed "s/\${DNS_NAME:-home\.internal}/$DNS_NAME/g" "$ROOT/srv/edge/cloudflared/config/config.yml.template" > "$ROOT/srv/edge/cloudflared/config/config.yml"
  echo "Generated: config.yml"
fi

echo "init ok: edge/cloudflared"
