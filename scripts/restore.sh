#!/usr/bin/env bash
# =============================================================================
# Canvas LMS — Restore Script
# Restores a backup created by backup.sh.
# WARNING: This will DROP and recreate the Canvas database!
# Usage: ./scripts/restore.sh <path/to/canvas_backup_YYYYMMDD_HHMMSS.tar.gz>
# =============================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

BACKUP_FILE="${1:-}"
[[ -n "$BACKUP_FILE" ]] || { echo "Usage: $0 <backup_file.tar.gz>"; exit 1; }
[[ -f "$BACKUP_FILE" ]] || { echo "Error: File not found: $BACKUP_FILE"; exit 1; }

# shellcheck disable=SC1091
source .env

TMP_DIR="$(mktemp -d)"

echo "[$(date)] Starting restore from: $BACKUP_FILE"
echo "WARNING: This will drop the current Canvas database. Press Ctrl+C within 5 seconds to abort."
sleep 5

# 1. Extract backup archive
echo "  -> Extracting backup..."
tar -xzf "$BACKUP_FILE" -C "$TMP_DIR"

# 2. Stop Canvas and job workers (keep postgres/redis running)
echo "  -> Stopping Canvas services..."
docker compose stop canvas canvas-jobs

# 3. Drop and recreate the database
echo "  -> Dropping and recreating database..."
docker compose exec -T postgres psql \
  -U "$POSTGRES_USER" \
  -c "DROP DATABASE IF EXISTS ${POSTGRES_DB};"
docker compose exec -T postgres psql \
  -U "$POSTGRES_USER" \
  -c "CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};"

# 4. Restore database dump
echo "  -> Restoring PostgreSQL database..."
docker compose exec -T postgres pg_restore \
  -U "$POSTGRES_USER" \
  -d "$POSTGRES_DB" \
  --no-owner \
  --no-privileges \
  < "${TMP_DIR}/database.dump"

# 5. Restore uploads (if present)
if [[ -d "${TMP_DIR}/uploads" ]]; then
  echo "  -> Restoring Canvas uploads..."
  docker compose cp "${TMP_DIR}/uploads" canvas:/usr/src/app/public/assets/uploads
else
    echo "  -> No uploads directory in backup — skipping."
fi

# 6. Cleanup
rm -rf "$TMP_DIR"

# 7. Restart Canvas
echo "  -> Restarting Canvas services..."
docker compose up -d canvas canvas-jobs

echo "[$(date)] Restore complete. Canvas is starting up at https://${CANVAS_DOMAIN}"
