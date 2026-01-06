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
touch "$ROOT/lib/traefik/acme.json"
chmod 600 "$ROOT/lib/traefik/acme.json"

# Process template files and generate actual YAML files
DNS_NAME="${DNS_NAME:-home.internal}"
export DNS_NAME

# Generate YAML files from templates
for template in "$ROOT/srv/edge/traefik/dynamic"/*.yml.template; do
  if [[ -f "$template" ]]; then
    output="${template%.template}"
    sed "s/\${DNS_NAME:-home\.internal}/$DNS_NAME/g" "$template" > "$output"
    echo "Generated: $output"
  fi
done

echo "init ok: edge/traefik"
