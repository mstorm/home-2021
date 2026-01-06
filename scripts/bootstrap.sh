#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script: Initial project setup (run once)
# Creates directory structure, Docker networks, and initial files

ROOT="${1:-.}"
# Convert to absolute path
ROOT="$(cd "$ROOT" && pwd)"

# Create directory structure
mkdir -p "$ROOT"/{srv,etc,lib,run,shared,docs,scripts}
mkdir -p "$ROOT"/run/{tmp,lock,logs,state}
mkdir -p "$ROOT"/shared/{backups,uploads,artifacts}

# Create Docker networks (idempotent - safe to run multiple times)
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

echo "bootstrap complete: $ROOT"
