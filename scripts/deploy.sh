#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"
# Convert to absolute path
ROOT="$(cd "$ROOT" && pwd)"
UNIT="${2:-all}"
export OPS_ROOT="$ROOT"

up_unit() {
  local u="$1"
  echo "up: $u"
  cd "$ROOT/srv/$u"
  docker compose -f compose.yml up -d
}

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

if [[ "$UNIT" == "all" ]]; then
  for u in "${ORDER[@]}"; do
    [[ -f "$ROOT/srv/$u/compose.yml" ]] && up_unit "$u"
  done
else
  up_unit "$UNIT"
fi
