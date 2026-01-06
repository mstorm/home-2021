# home-2021

## Setup `OPS_ROOT`

The `OPS_ROOT` environment variable specifies the root directory for all operations. By default, scripts use the current directory (`.`) as the base path.

```bash
# Use current directory (default)
./scripts/bootstrap.sh

# Use specific directory
./scripts/bootstrap.sh ~/ops

# Or set OPS_ROOT environment variable
export OPS_ROOT=~/ops
./scripts/bootstrap.sh
```

All `compose.yml` files use `${OPS_ROOT:-.}` for paths, which means:
- If `OPS_ROOT` is set, it uses that absolute path
- If not set, it defaults to `.` (current directory where compose.yml is located)

Scripts automatically convert the `ROOT` argument to an absolute path and export it as `OPS_ROOT`.

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
