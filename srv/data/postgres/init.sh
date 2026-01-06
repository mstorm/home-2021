#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-.}"
# Convert to absolute path
ROOT="$(cd "$ROOT" && pwd)"
# Ensure generic runtime dirs exist
mkdir -p "$ROOT/run"/{tmp,lock,logs,state}
mkdir -p "$ROOT/lib/postgres"

echo "init ok: data/postgres"
