#!/usr/bin/env bash
set -euo pipefail

# Preflight script: Pre-deployment checks and initialization
# Run before each deployment to ensure dependencies and run service init scripts

ROOT="${1:-.}"
# Convert to absolute path
ROOT="$(cd "$ROOT" && pwd)"

require() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1"; exit 1; }; }

# Check dependencies
require docker
docker compose version >/dev/null 2>&1 || { echo "Missing docker compose plugin"; exit 1; }

# Ensure Docker networks exist (idempotent - safe if already created by bootstrap.sh)
if ! docker network inspect net_external >/dev/null 2>&1; then
  docker network create net_external
fi
if ! docker network inspect net_internal >/dev/null 2>&1; then
  docker network create net_internal
fi

# Run init.sh in canonical order (does not start containers)
ORDER=(
  "edge/traefik"
  "edge/cloudflared"
  "data/postgres"
  "data/redis"
  "foundation/zitadel"
  "foundation/headscale"
  "observability/prometheus"
  "observability/loki"
  "observability/promtail"
  "observability/alertmanager"
  "observability/grafana"
  "observability/uptime-kuma"
  "apps/gitea"
      "apps/portainer"
      "apps/registry"
  "apps/vaultwarden"
  "apps/n8n"
  "apps/teslamate"
  "apps/unifi"
)

for u in "${ORDER[@]}"; do
  if [[ -f "$ROOT/srv/$u/init.sh" ]]; then
    echo "init: $u"
    bash "$ROOT/srv/$u/init.sh" "$ROOT"
  fi
done

echo "preflight complete"
