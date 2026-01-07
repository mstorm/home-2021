# home-2021

## Operations Script

All operations are handled by a single unified script `ops.sh` in the project root.

```bash
# Show usage
./ops.sh

# Commands
./ops.sh bootstrap              # Initial project setup (run once)
./ops.sh preflight             # Pre-deployment checks and initialization
./ops.sh up all                # Deploy all services
./ops.sh up edge/traefik       # Deploy specific service
./ops.sh down                  # Stop all services
./ops.sh down apps/vaultwarden # Stop specific service
./ops.sh validate edge/traefik # Validate compose.yml
./ops.sh up debug/env          # Check environment variables
```

The script automatically detects the project root from its location and exports it as `OPS_ROOT`. All `compose.yml` files use `${OPS_ROOT:-.}` for paths.

## ops layout

This is the canonical directory layout. The default location is the current directory, but can be configured via `OPS_ROOT`.

- `srv/`: docker compose units (Git-tracked)
- `etc/`: `*.env.example` templates (Git-tracked). Real `*.env` must NOT be committed.
- `lib/`: persistent volumes (not tracked)
- `run/`: runtime (not tracked)
- `shared/`: NAS mountpoint for backups/uploads/artifacts (not tracked)
- `docs/`, `scripts/`: docs & helper scripts (Git-tracked)

Networks (external):
- `net_internal`
- `net_external`
