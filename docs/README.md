# Docs

## Installation Order

### 1. Prerequisites

The following tools must be installed:
- Docker
- Docker Compose (plugin)

```bash
# Verify Docker and Docker Compose
docker --version
docker compose version
```

### 2. Directory Structure Creation and Initial Setup

Run the `bootstrap` command to create the directory structure and perform initial setup:

```bash
./ops.sh bootstrap
```

This command performs the following:
- Creates directory structure (`srv/`, `etc/`, `lib/`, `run/`, `shared/`, `docs/`, `scripts/`)
- Creates Docker networks (`net_external`, `net_internal`)
- Creates Traefik ACME storage and sets permissions

**Note:** The script automatically detects the project root from its location, so you can run it from anywhere.

### 3. Environment Variable Configuration

Create actual `.env` files based on the `.env.example` files in the `etc/` directory:

```bash
# Global environment variables
cp etc/global.env.example etc/global.env
# Modify as needed

# Service-specific environment variables
cp etc/srv/edge.traefik.env.example etc/srv/edge.traefik.env
cp etc/srv/edge.cloudflared.env.example etc/srv/edge.cloudflared.env
# ... other required services
```

**Important Settings:**
- `edge.traefik.env`: Let's Encrypt email and Cloudflare DNS-01 API token
- `edge.cloudflared.env`: Cloudflare Tunnel token or credentials.json
- Other service-specific environment variables as needed

### 4. DNS Configuration

Configure internal DNS settings. See [dns.md](./dns.md) for details.

Key settings:
- `*.home.mstorm.net` → Traefik (VM IP)
- `home.mstorm.net` → Traefik (VM IP)
- External Cloudflare Tunnel domain configuration (id.mstorm.net, vault.mstorm.net, etc.)

### 5. Initialization

Run the `preflight` command to execute initialization scripts for each service:

```bash
./ops.sh preflight
```

This command runs each service's `init.sh` in the following order:
1. `edge/traefik`
2. `edge/cloudflared`
3. `data/postgres`
4. `data/redis`
5. `foundation/zitadel`
6. `foundation/headscale`
7. `observability/prometheus`
8. `observability/loki`
9. `observability/promtail`
10. `observability/alertmanager`
11. `observability/grafana`
12. `observability/uptime-kuma`
13. `apps/gitea`
14. `apps/portainer`
15. `apps/registry`
16. `apps/vaultwarden`
17. `apps/n8n`
18. `apps/teslamate`
19. `apps/unifi`

### 6. Service Deployment

Run the `deploy` command to deploy services:

```bash
# Deploy all services
./ops.sh deploy

# Deploy specific service only
./ops.sh deploy edge/traefik
```

The deployment order is the same as the initialization order.

**Path Configuration:**
- The script automatically detects the project root from its location.
- The detected root is exported as `OPS_ROOT` environment variable.
- All `compose.yml` files use `${OPS_ROOT:-.}` for paths.
- You can run the script from anywhere - it will always find the correct project root.

### 7. TLS Certificate Configuration

Traefik is configured to automatically obtain Let's Encrypt certificates. See [tls.md](./tls.md) for details.

**Warnings:**
- Do NOT expose the Traefik dashboard to the internet.
- Ensure the ACME storage file (`lib/traefik/acme.json`) has permissions set to 600.

### 8. Validation

To validate each service's `compose.yml` file:

```bash
./ops.sh validate <unit-path>
```

Example:
```bash
./ops.sh validate edge/traefik
```

### 9. Stopping Services

To stop services:

```bash
# Stop all services (in reverse order)
./ops.sh down

# Stop specific service
./ops.sh down apps/vaultwarden
```
