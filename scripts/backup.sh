#!/usr/bin/env bash
# =============================================================================
# Canvas LMS — Backup Script
# Creates a timestamped backup of the PostgreSQL database and Canvas uploads.
# Backup is saved to ./backups/ as a single .tar.gz archive.
# Usage: ./scripts/backup.sh
# =============================================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

# shellcheck disable=SC1091
source .env

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$PROJECT_DIR/backups"
BACKUP_NAME="canvas_backup_${TIMESTAMP}"
TMP_DIR="$(mktemp -d)"

mkdir -p "$BACKUP_DIR"

echo "[$(date)] Starting Canvas backup: $BACKUP_NAME"

# 1. Dump PostgreSQL
echo "  -> Dumping PostgreSQL database..."
docker compose exec -T postgres pg_dump \
  -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
      --no-owner \
        --no-privileges \
          -Fc \
            > "${TMP_DIR}/database.dump"

            # 2. Copy uploaded files from the canvas container
            echo "  -> Copying Canvas uploads..."
            docker compose cp canvas:/usr/src/app/public/assets/uploads "${TMP_DIR}/uploads" 2>/dev/null || \
              echo "     (no uploads directory found — skipping)"

              # 3. Package everything
              echo "  -> Creating archive: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
              tar -czf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" -C "$TMP_DIR" .

              # 4. Cleanup
              rm -rf "$TMP_DIR"

              BACKUP_SIZE="$(du -sh "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)"
              echo "[$(date)] Backup complete: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz (${BACKUP_SIZE})"
