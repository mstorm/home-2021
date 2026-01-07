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

# Store original password value to check if it was __REPLACE_ME__
ZITADEL_DATABASE_PASSWORD_OLD="${ZITADEL_DATABASE_PASSWORD:-}"

# Generate new password only if not set or set to __REPLACE_ME__
if [ -z "${ZITADEL_DATABASE_PASSWORD:-}" ] || [ "${ZITADEL_DATABASE_PASSWORD}" = "__REPLACE_ME__" ]; then
  echo "Generating a secure password for Zitadel database user..."
  # Use openssl for reliable password generation (32 characters)
  if command -v openssl >/dev/null 2>&1; then
    # Generate 32 bytes and base64 encode, then take first 32 alphanumeric chars
    ZITADEL_DATABASE_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | tr -d '\n' | head -c 32)
  else
    # Fallback: use date + process ID + random for seed, then hash
    SEED=$(date +%s%N)${$}$(od -An -N4 -tu4 /dev/urandom 2>/dev/null | tr -d ' ')
    ZITADEL_DATABASE_PASSWORD=$(echo -n "$SEED" | sha256sum | cut -d' ' -f1 | head -c 32)
  fi
  echo "✓ Password generated"
else
  echo "Using existing password from environment file"
fi

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

# Create or update user
if docker exec postgres psql -U "$POSTGRES_USER" -d postgres -tc "SELECT 1 FROM pg_roles WHERE rolname = 'zitadel'" | grep -q 1; then
  # User exists - update password
  echo "User 'zitadel' already exists, updating password..."
  docker exec postgres psql -U "$POSTGRES_USER" -d postgres -c "ALTER USER zitadel WITH PASSWORD '${ZITADEL_DATABASE_PASSWORD}';"
else
  # User doesn't exist - create new user
  echo "Creating user 'zitadel' with password..."
  docker exec postgres psql -U "$POSTGRES_USER" -d postgres -c "CREATE USER zitadel WITH PASSWORD '${ZITADEL_DATABASE_PASSWORD}';"
fi

# Grant privileges
echo "Granting privileges..."
docker exec postgres psql -U "$POSTGRES_USER" -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE zitadel TO zitadel;"
docker exec postgres psql -U "$POSTGRES_USER" -d zitadel -c "GRANT ALL ON SCHEMA public TO zitadel;"
docker exec postgres psql -U "$POSTGRES_USER" -d zitadel -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO zitadel;"
docker exec postgres psql -U "$POSTGRES_USER" -d zitadel -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO zitadel;"

# Save password to foundation.zitadel.env only if we generated a new one
if [ -z "${ZITADEL_DATABASE_PASSWORD_OLD:-}" ] || [ "${ZITADEL_DATABASE_PASSWORD_OLD}" = "__REPLACE_ME__" ]; then
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
fi

echo ""
echo "✓ Zitadel database and user created successfully!"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Database Configuration"
echo "═══════════════════════════════════════════════════════════════"
echo "  Database: zitadel"
echo "  User:     zitadel"
if [ -z "${ZITADEL_DATABASE_PASSWORD_OLD:-}" ] || [ "${ZITADEL_DATABASE_PASSWORD_OLD}" = "__REPLACE_ME__" ]; then
  echo "  Password: $ZITADEL_DATABASE_PASSWORD"
  echo ""
  echo "✓ Password saved to etc/srv/foundation.zitadel.env"
else
  echo "  Password: (using existing password from environment file)"
fi
echo "═══════════════════════════════════════════════════════════════"

