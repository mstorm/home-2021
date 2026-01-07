#!/usr/bin/env bash
set -euo pipefail

# Unified operations script
# Automatically detects project root from script location

# Get script directory (which is the project root)
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export OPS_ROOT="$ROOT"

# Service deployment order
ORDER=(
  "edge/lego"
  "edge/traefik"
  "edge/cloudflared"
  "data/postgres"
  "data/redis"
  "foundation/smtp"
  "foundation/zitadel"
  "foundation/headscale"
  "observability/node-exporter"
  "observability/cadvisor"
  "observability/prometheus"
  "observability/loki"
  "observability/promtail"
  "observability/alertmanager"
  "observability/grafana"
  "observability/dozzle"
  "observability/uptime-kuma"
  "observability/watchtower"
  "apps/gitea"
  "apps/portainer"
  "apps/registry"
  "apps/vaultwarden"
  "apps/n8n"
  "apps/teslamate"
  "apps/unifi"
)

# Helper functions
require() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1"; exit 1; }
}

# Resolve unit name to full path
# If input is already "type/name", return as-is
# If input is just "name", search ORDER array first, then filesystem
resolve_unit() {
  local input="$1"
  
  # If already contains '/', assume it's a full path
  if [[ "$input" == */* ]]; then
    echo "$input"
    return
  fi
  
  # First, search ORDER array for matching name
  for unit in "${ORDER[@]}"; do
    if [[ "$unit" == */"$input" ]]; then
      echo "$unit"
      return
    fi
  done
  
  # If not found in ORDER, search filesystem
  local srv_dir="$ROOT/srv"
  if [[ -d "$srv_dir" ]]; then
    while IFS= read -r -d '' dir; do
      local rel_path="${dir#$srv_dir/}"
      if [[ "$rel_path" == */* ]] && [[ "${rel_path##*/}" == "$input" ]]; then
        echo "$rel_path"
        return
      fi
    done < <(find "$srv_dir" -mindepth 2 -maxdepth 2 -type d -print0 2>/dev/null)
  fi
  
  # If not found, return original (will fail later with proper error)
  echo "$input"
}

# Get unit directory path
# Resolves unit name and returns full directory path
get_unit_dir() {
  local unit="$1"
  unit="$(resolve_unit "$unit")"
  echo "$ROOT/srv/$unit"
}

# Get unit compose file
# Returns compose file path or empty string if not found
get_unit_compose_file() {
  local unit="$1"
  local unit_dir
  unit_dir="$(get_unit_dir "$unit")"
  find_compose_file "$unit_dir"
}

# Find compose file in a directory
# Returns the compose file path or empty string if not found
# Exits with error if multiple compose files are found
find_compose_file() {
  local dir="$1"
  local files=()
  # Docker Compose standard file names (in priority order)
  local compose_files=(
    "compose.yml"
    "compose.yaml"
    "docker-compose.yml"
    "docker-compose.yaml"
  )
  local file
  
  # Check all possible compose file names
  for file in "${compose_files[@]}"; do
    [[ -f "$dir/$file" ]] && files+=("$file")
  done
  
  # Error if multiple files found
  if [[ ${#files[@]} -gt 1 ]]; then
    echo "Error: Multiple compose files found in $dir:" >&2
    for f in "${files[@]}"; do
      echo "  - $f" >&2
    done
    echo "Please remove duplicate files." >&2
    exit 1
  fi
  
  # Return the found file or empty string
  [[ ${#files[@]} -eq 1 ]] && echo "${files[0]}"
}

# Load env files for Docker Compose variable substitution
load_env_files() {
  local compose_file="$1"
  local unit_dir="$2"
  
  # Extract env_file paths from compose.yml
  local in_env_file=false
  while IFS= read -r line; do
    if [[ "$line" =~ env_file: ]]; then
      in_env_file=true
      continue
    fi
    if [[ "$in_env_file" == true ]]; then
      if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*(.+) ]]; then
        local env_path="${BASH_REMATCH[1]}"
        # Remove quotes if present
        env_path="${env_path#\"}"
        env_path="${env_path%\"}"
        # Replace ${OPS_ROOT:-../../../} with $ROOT using sed
        env_path=$(echo "$env_path" | sed "s|\${OPS_ROOT:-\.\.\/\.\.\/\.\.\/}|$ROOT|g")
        # If path is relative and starts with ../../ or ../../../, resolve from ROOT
        if [[ "$env_path" =~ ^\.\./\.\./\.\./ ]]; then
          env_path="$ROOT/${env_path#../../../}"
        elif [[ "$env_path" =~ ^\.\./\.\./ ]]; then
          env_path="$ROOT/${env_path#../../}"
        elif [[ "$env_path" != /* ]]; then
          # Other relative paths resolve from unit_dir
          env_path="$(cd "$unit_dir" && cd "$(dirname "$env_path")" && pwd)/$(basename "$env_path")"
        fi
        if [[ -f "$env_path" ]]; then
          set -a
          source "$env_path"
          set +a
        fi
      elif [[ "$line" =~ ^[[:space:]]*[a-zA-Z] ]] && [[ ! "$line" =~ ^[[:space:]]*- ]]; then
        # End of env_file section
        break
      fi
    fi
  done < "$compose_file"
}

up_unit() {
  local u="$1"
  local follow_logs="${2:-false}"
  local unit_dir
  local compose_file
  
  unit_dir="$(get_unit_dir "$u")"
  echo "up: $u"
  
  # Run init.sh if it exists (for template file generation, etc.)
  if [[ -f "$unit_dir/init.sh" ]]; then
    echo "init: $u"
    bash "$unit_dir/init.sh" "$ROOT"
  fi
  
  cd "$unit_dir"
  
  compose_file="$(get_unit_compose_file "$u")"
  if [[ -z "$compose_file" ]]; then
    echo "Error: No compose file found in $unit_dir" >&2
    exit 1
  fi
  
  # Load env files for Docker Compose variable substitution
  load_env_files "$compose_file" "$unit_dir"
  
  # Use up with --force-recreate to apply config/env changes
  # Environment variables loaded by load_env_files are already exported (set -a)
  if [[ "$follow_logs" == "true" ]]; then
    # Run in foreground mode - logs are shown and process exits when containers stop
    OPS_ROOT="$ROOT" docker compose -f "$compose_file" up --force-recreate
  else
    # Run in detached mode
    OPS_ROOT="$ROOT" docker compose -f "$compose_file" up -d --force-recreate
  fi
}

down_unit() {
  local u="$1"
  local unit_dir
  local compose_file
  
  unit_dir="$(get_unit_dir "$u")"
  echo "down: $u"
  cd "$unit_dir"
  
  compose_file="$(get_unit_compose_file "$u")"
  if [[ -z "$compose_file" ]]; then
    echo "Error: No compose file found in $unit_dir" >&2
    exit 1
  fi
  
  docker compose -f "$compose_file" down
}

# Commands
cmd_bootstrap() {
  echo "bootstrap: $ROOT"
  
  # Create directory structure (only non-tracked directories)
  mkdir -p "$ROOT"/{lib,run,shared}
  mkdir -p "$ROOT"/run/{tmp,lock,logs,state}
  mkdir -p "$ROOT"/shared/{backups,uploads,artifacts}
  
  # Create Docker networks (idempotent)
  if ! docker network inspect net_external >/dev/null 2>&1; then
    docker network create net_external
  fi
  if ! docker network inspect net_internal >/dev/null 2>&1; then
    docker network create net_internal
  fi
  
  # Traefik ACME storage
  mkdir -p "$ROOT/lib/traefik"
  touch "$ROOT/lib/traefik/acme.json"
  chmod 600 "$ROOT/lib/traefik/acme.json"
  
  echo "bootstrap complete"
}

cmd_preflight() {
  echo "preflight: $ROOT"
  
  # Check dependencies
  require docker
  docker compose version >/dev/null 2>&1 || { echo "Missing docker compose plugin"; exit 1; }
  
  # Ensure Docker networks exist
  if ! docker network inspect net_external >/dev/null 2>&1; then
    docker network create net_external
  fi
  if ! docker network inspect net_internal >/dev/null 2>&1; then
    docker network create net_internal
  fi
  
  # Run init.sh in canonical order
  for u in "${ORDER[@]}"; do
    if [[ -f "$ROOT/srv/$u/init.sh" ]]; then
      echo "init: $u"
      bash "$ROOT/srv/$u/init.sh" "$ROOT"
    fi
  done
  
  echo "preflight complete"
}

cmd_up() {
  local unit=""
  local follow_logs=false
  local args=("$@")
  
  # Parse arguments - find unit and --follow/-f flag
  # First, find all flags
  for arg in "${args[@]}"; do
    if [[ "$arg" == "--follow" ]] || [[ "$arg" == "-f" ]]; then
      follow_logs=true
    fi
  done
  
  # Then, find the first non-flag argument as unit
  for arg in "${args[@]}"; do
    if [[ "$arg" != "--follow" ]] && [[ "$arg" != "-f" ]]; then
      unit="$arg"
      break
    fi
  done
  
  if [[ -z "$unit" ]]; then
    echo "Usage: $0 up <unit|all> [--follow|-f]"
    echo "Example: $0 up all"
    echo "Example: $0 up edge/traefik"
    echo "Example: $0 up traefik"
    echo "Example: $0 up debug/env --follow"
    echo "Example: $0 up --follow debug/env"
    exit 2
  fi
  
  if [[ "$unit" == "all" ]]; then
    if [[ "$follow_logs" == "true" ]]; then
      echo "Warning: --follow is not supported with 'all', using detached mode" >&2
    fi
    for u in "${ORDER[@]}"; do
      # Check if any compose file exists
      if get_unit_compose_file "$u" >/dev/null 2>&1; then
        up_unit "$u" false
      fi
    done
  else
    unit="$(resolve_unit "$unit")"
    up_unit "$unit" "$follow_logs"
  fi
}

cmd_down() {
  local unit="${1:-}"
  
  if [[ -z "$unit" ]]; then
    echo "Usage: $0 down <unit|all>"
    echo "Example: $0 down all"
    echo "Example: $0 down apps/vaultwarden"
    echo "Example: $0 down vaultwarden"
    exit 2
  fi
  
  if [[ "$unit" == "all" ]]; then
    # Reverse order for shutdown
    for ((idx=${#ORDER[@]}-1 ; idx>=0 ; idx--)); do
      u="${ORDER[$idx]}"
      # Check if any compose file exists
      if get_unit_compose_file "$u" >/dev/null 2>&1; then
        down_unit "$u"
      fi
    done
  else
    unit="$(resolve_unit "$unit")"
    down_unit "$unit"
  fi
}

cmd_validate() {
  local unit="${1:-}"
  
  if [[ -z "$unit" ]]; then
    echo "Usage: $0 validate <unit-path>"
    echo "Example: $0 validate edge/traefik"
    echo "Example: $0 validate traefik"
    exit 2
  fi
  
  local unit_dir
  local compose_file
  
  unit_dir="$(get_unit_dir "$unit")"
  cd "$unit_dir"
  
  compose_file="$(get_unit_compose_file "$unit")"
  if [[ -z "$compose_file" ]]; then
    echo "Error: No compose file found in $unit_dir" >&2
    exit 1
  fi
  
  docker compose -f "$compose_file" config >/dev/null
  echo "OK: $(resolve_unit "$unit")"
}

cmd_status() {
  local unit="${1:-all}"
  local unit_dir
  local compose_file
  
  if [[ "$unit" == "all" ]]; then
    # Show status for all services
    for u in "${ORDER[@]}"; do
      unit_dir="$(get_unit_dir "$u")"
      compose_file="$(get_unit_compose_file "$u" 2>/dev/null)"
      if [[ -n "$compose_file" ]]; then
        echo "=== $u ==="
        cd "$unit_dir"
        docker compose -f "$compose_file" ps
        echo ""
      fi
    done
  else
    unit_dir="$(get_unit_dir "$unit")"
    compose_file="$(get_unit_compose_file "$unit")"
    if [[ -z "$compose_file" ]]; then
      echo "Error: No compose file found in $unit_dir" >&2
      exit 1
    fi
    cd "$unit_dir"
    docker compose -f "$compose_file" ps
  fi
}

cmd_logs() {
  local unit="${1:-}"
  local service="${2:-}"
  local unit_dir
  local compose_file
  
  if [[ -z "$unit" ]]; then
    echo "Usage: $0 logs <unit-path> [service-name]"
    echo "Example: $0 logs edge/traefik"
    echo "Example: $0 logs traefik"
    echo "Example: $0 logs edge/traefik traefik"
    exit 2
  fi
  
  local unit_dir
  local compose_file
  
  unit_dir="$(get_unit_dir "$unit")"
  compose_file="$(get_unit_compose_file "$unit")"
  if [[ -z "$compose_file" ]]; then
    echo "Error: No compose file found in $unit_dir" >&2
    exit 1
  fi
  
  cd "$unit_dir"
  if [[ -n "$service" ]]; then
    docker compose -f "$compose_file" logs -f "$service"
  else
    docker compose -f "$compose_file" logs -f
  fi
}

# Alias: restart = down + up
cmd_restart() {
  local unit="${1:-}"
  
  if [[ -z "$unit" ]]; then
    echo "Usage: $0 restart <unit|all>"
    echo "Example: $0 restart all"
    echo "Example: $0 restart edge/traefik"
    echo "Example: $0 restart traefik"
    exit 2
  fi
  
  cmd_down "$unit"
  cmd_up "$unit"
}

# Main command dispatcher
COMMAND="${1:-}"
TARGET="${2:-}"
OPTION="${3:-}"

case "$COMMAND" in
  bootstrap)
    cmd_bootstrap
    ;;
  preflight)
    cmd_preflight
    ;;
  up)
    shift  # Remove 'up' command
    cmd_up "$@"
    ;;
  down)
    cmd_down "$TARGET"
    ;;
  restart)
    cmd_restart "$TARGET"
    ;;
  validate)
    cmd_validate "$TARGET"
    ;;
  status)
    cmd_status "$TARGET"
    ;;
  logs)
    cmd_logs "$TARGET" "$OPTION"
    ;;
  *)
    echo "Usage: $0 <command> [target] [options]"
    echo ""
    echo "Commands:"
    echo "  bootstrap              - Initial project setup (run once)"
    echo "  preflight              - Pre-deployment checks and initialization"
    echo "  up <unit|all>          - Start services (runs init.sh, applies config/env changes)"
    echo "  down <unit|all>        - Stop services"
    echo "  restart <unit|all>    - Restart services (down + up)"
    echo "  status [unit|all]      - Show service status (default: all)"
    echo "  logs <unit> [service]  - Show service logs (follow mode)"
    echo "  validate <unit>       - Validate compose.yml for a service"
    echo ""
    echo "Examples:"
    echo "  $0 bootstrap"
    echo "  $0 preflight"
    echo "  $0 up all"
    echo "  $0 up edge/traefik"
    echo "  $0 down all"
    echo "  $0 down apps/vaultwarden"
    echo "  $0 restart edge/traefik"
    echo "  $0 status"
    echo "  $0 status edge/traefik"
    echo "  $0 logs edge/traefik"
    echo "  $0 logs edge/traefik traefik"
    echo "  $0 validate edge/traefik"
    exit 1
    ;;
esac

