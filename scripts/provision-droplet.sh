#!/usr/bin/env bash
set -euo pipefail

# provision-droplet.sh — One-time droplet setup for Vaultwarden
# This is idempotent — safe to re-run.
#
# Run this ONCE on the droplet to:
# - Create vaultwarden directory under /opt/
# - Set up the deploy structure
# - Install restic for backups

echo "=== Droplet Provisioning: Vaultwarden ==="

# Create deployment directory
mkdir -p /opt/vaultwarden
mkdir -p /opt/vaultwarden/backups

# Install restic
if ! command -v restic &>/dev/null; then
    apt-get update && apt-get install -y restic
fi

# Create log directory
mkdir -p /var/log/vaultwarden

echo "=== Provisioning complete ==="
echo "Next: deploy the repository contents to /opt/vaultwarden/"
