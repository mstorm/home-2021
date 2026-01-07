#!/usr/bin/env bash
set -euo pipefail

# Script to manually create Zitadel database and user for existing PostgreSQL instance
# Usage: ./scripts/setup-zitadel-db.sh

# Get script directory (project root)
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export OPS_ROOT="$ROOT"

# Load environment variables
if [ -f "$ROOT/etc/srv/data.postgres.env" ]; then
  set -a
  source "$ROOT/etc/srv/data.postgres.env"
  set +a
else
  echo "Error: $ROOT/etc/srv/data.postgres.env not found"
  echo "Please create it from etc/srv/data.postgres.env.example"
  exit 1
fi

if [ -f "$ROOT/etc/srv/foundation.zitadel.env" ]; then
  set -a
  source "$ROOT/etc/srv/foundation.zitadel.env"
  set +a
else
  echo "Error: $ROOT/etc/srv/foundation.zitadel.env not found"
  echo "Please create it from etc/srv/foundation.zitadel.env.example"
  exit 1
fi

# Check if postgres container is running
if ! docker ps --format '{{.Names}}' | grep -q '^postgres$'; then
  echo "Error: PostgreSQL container 'postgres' is not running"
  exit 1
fi

# Generate new password
echo "Generating a secure password for Zitadel database user..."
ZITADEL_DATABASE_PASSWORD=$(tr -dc 'A-Za-z0-9!@#$%^&*' </dev/urandom | head -c 32)
echo "✓ Password generated"

POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-}"

echo "Creating Zitadel database and user..."

# Create database if it doesn't exist
if docker exec postgres psql -U "$POSTGRES_USER" -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'zitadel'" | grep -q 1; then
  echo "Database 'zitadel' already exists"
else
  echo "Creating database 'zitadel'..."
  docker exec postgres psql -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE zitadel;"
fi

# Drop user if exists (to recreate with new password)
if docker exec postgres psql -U "$POSTGRES_USER" -d postgres -tc "SELECT 1 FROM pg_roles WHERE rolname = 'zitadel'" | grep -q 1; then
  echo "User 'zitadel' already exists, dropping and recreating..."
  docker exec postgres psql -U "$POSTGRES_USER" -d postgres -c "DROP USER IF EXISTS zitadel;"
fi

# Create new user with generated password
echo "Creating user 'zitadel' with new password..."
docker exec postgres psql -U "$POSTGRES_USER" -d postgres -c "CREATE USER zitadel WITH PASSWORD '${ZITADEL_DATABASE_PASSWORD}';"

# Grant privileges
echo "Granting privileges..."
docker exec postgres psql -U "$POSTGRES_USER" -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE zitadel TO zitadel;"
docker exec postgres psql -U "$POSTGRES_USER" -d zitadel -c "GRANT ALL ON SCHEMA public TO zitadel;"
docker exec postgres psql -U "$POSTGRES_USER" -d zitadel -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO zitadel;"
docker exec postgres psql -U "$POSTGRES_USER" -d zitadel -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO zitadel;"

# Save password to foundation.zitadel.env
ZITADEL_ENV_FILE="$ROOT/etc/srv/foundation.zitadel.env"
echo ""
echo "Saving password to $ZITADEL_ENV_FILE..."

if grep -q "^ZITADEL_DATABASE_PASSWORD=" "$ZITADEL_ENV_FILE" 2>/dev/null; then
  # Update existing password
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS sed
    sed -i '' "s|^ZITADEL_DATABASE_PASSWORD=.*|ZITADEL_DATABASE_PASSWORD=$ZITADEL_DATABASE_PASSWORD|" "$ZITADEL_ENV_FILE"
  else
    # Linux sed
    sed -i "s|^ZITADEL_DATABASE_PASSWORD=.*|ZITADEL_DATABASE_PASSWORD=$ZITADEL_DATABASE_PASSWORD|" "$ZITADEL_ENV_FILE"
  fi
  echo "✓ Updated existing ZITADEL_DATABASE_PASSWORD"
else
  # Append new password
  echo "" >> "$ZITADEL_ENV_FILE"
  echo "ZITADEL_DATABASE_PASSWORD=$ZITADEL_DATABASE_PASSWORD" >> "$ZITADEL_ENV_FILE"
  echo "✓ Added ZITADEL_DATABASE_PASSWORD"
fi

echo ""
echo "✓ Zitadel database and user created successfully!"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Database Configuration"
echo "═══════════════════════════════════════════════════════════════"
echo "  Database: zitadel"
echo "  User:     zitadel"
echo "  Password: $ZITADEL_DATABASE_PASSWORD"
echo ""
echo "✓ Password saved to etc/srv/foundation.zitadel.env"
echo "═══════════════════════════════════════════════════════════════"

