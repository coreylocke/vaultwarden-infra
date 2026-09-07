#!/usr/bin/env bash
set -euo pipefail

# restore.sh — Restore Vaultwarden from a restic snapshot
# Usage: ./scripts/restore.sh [snapshot_id]
# If no snapshot_id is given, shows available snapshots.

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SCRIPT_DIR"

# Load .env if present
if [ -f "${SCRIPT_DIR}/.env" ]; then
    set -a
    source "${SCRIPT_DIR}/.env"
    set +a
fi

if ! command -v restic &>/dev/null; then
    echo "ERROR: restic is not installed."
    exit 1
fi

if [ -z "${RESTIC_REPOSITORY:-}" ]; then
    echo "ERROR: RESTIC_REPOSITORY is not set."
    exit 1
fi

if [ $# -eq 0 ]; then
    echo "=== Available Vaultwarden Snapshots ==="
    restic snapshots --tag vaultwarden
    echo ""
    echo "Usage: $0 <snapshot_id>"
    exit 0
fi

SNAPSHOT_ID="$1"
echo "Restoring snapshot: $SNAPSHOT_ID"

# Stop Vaultwarden
echo "Stopping vaultwarden..."
docker stop vaultwarden 2>/dev/null || true

# Restore from restic
echo "Restoring from restic..."
restic restore "$SNAPSHOT_ID" --target /tmp/vw-restore

# Find and extract the archive
ARCHIVE=$(find /tmp/vw-restore -name "vw-backup-*.tar.gz" | head -1)
if [ -z "$ARCHIVE" ]; then
    echo "ERROR: No backup archive found in snapshot."
    exit 1
fi

# Backup current data just in case
echo "Backing up current data..."
mv vw-data "vw-data.bak.$(date +%Y%m%d_%H%M%S)"

# Extract the restored data
echo "Extracting restored data..."
tar xzf "$ARCHIVE" -C "$SCRIPT_DIR"

# Clean up
rm -rf /tmp/vw-restore

# Start Vaultwarden
echo "Starting vaultwarden..."
docker start vaultwarden 2>/dev/null || true

echo "=== Restore complete ==="
