#!/usr/bin/env bash
set -euo pipefail

# backup.sh — Encrypted Vaultwarden backup using restic
# Prerequisites: restic installed, restic repo initialized
# Run from the vaultwarden-infra directory.
#
# Usage: ./scripts/backup.sh
#
# Environment variables required (set in .env or exported):
#   RESTIC_REPOSITORY  — e.g. s3:s3.us-east-1.wasabisys.com/vaultwarden-backups
#   RESTIC_PASSWORD    — restic repo encryption password
#   AWS_ACCESS_KEY_ID  — S3-compatible storage access key
#   AWS_SECRET_ACCESS_KEY — S3-compatible storage secret key

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${SCRIPT_DIR}/backups"

# Load .env if present
if [ -f "${SCRIPT_DIR}/.env" ]; then
    set -a
    source "${SCRIPT_DIR}/.env"
    set +a
fi

# Verify prerequisites
for cmd in restic docker; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: $cmd is not installed."
        exit 1
    fi
done

if [ -z "${RESTIC_REPOSITORY:-}" ]; then
    echo "ERROR: RESTIC_REPOSITORY is not set."
    exit 1
fi

mkdir -p "$BACKUP_DIR"

echo "=== Vaultwarden Backup: $TIMESTAMP ==="

# 1. Stop vaultwarden to ensure consistent SQLite state
echo "Stopping vaultwarden..."
docker stop vaultwarden 2>/dev/null || true
sleep 2

# 2. Create a compressed archive of the data directory
echo "Archiving vw-data..."
tar czf "${BACKUP_DIR}/vw-backup-${TIMESTAMP}.tar.gz" \
    -C "$SCRIPT_DIR" \
    vw-data/

# 3. Restart vaultwarden
echo "Restarting vaultwarden..."
docker start vaultwarden 2>/dev/null || true

# 4. Encrypt and send to restic repository
echo "Sending to restic repository..."
restic backup \
    "${BACKUP_DIR}/vw-backup-${TIMESTAMP}.tar.gz" \
    --host vaultwarden \
    --tag vaultwarden \
    --tag "$TIMESTAMP"

# 5. Prune old snapshots (keep last 30 daily, 12 weekly, 6 monthly)
echo "Pruning old snapshots..."
restic forget \
    --keep-daily 30 \
    --keep-weekly 12 \
    --keep-monthly 6 \
    --prune

# 6. Clean up local archive
rm -f "${BACKUP_DIR}/vw-backup-${TIMESTAMP}.tar.gz"

echo "=== Backup complete ==="
restic snapshots
