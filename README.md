# Vaultwarden — Self-Hosted Password Manager

[Vaultwarden](https://github.com/dani-garcia/vaultwarden) is a lightweight, self-hosted implementation of the Bitwarden server API. This repository contains the deployment configuration for **vaultwarden.lockeinvestments.net**.

## Architecture

```
Internet → Cloudflare (DNS proxy) → Caddy (TLS termination) → Vaultwarden (Docker)
```

- **Caddy** handles HTTPS with automatic Let's Encrypt certificates via Cloudflare DNS challenge
- **Vaultwarden** runs on an internal Docker network with no public port exposure
- **Data** is persisted in `./vw-data/` (SQLite + attachments)
- **Backups** are encrypted with restic and pushed to S3-compatible storage

## Requirements

- Docker and Docker Compose on the host
- Domain DNS pointing to the host (via Cloudflare)
- Restic (for backups)

## Deployment

```bash
# 1. Clone this repo on the server
git clone https://github.com/coreylocke/vaultwarden-infra.git
cd vaultwarden-infra

# 2. Create .env from example
cp .env.example .env
# Edit .env with your domain and admin token

# 3. Generate an argon2-hashed admin token
echo -n "YourMasterPassword" | argon2 "$(openssl rand -base64 32)" -e -id -k 65540 -t 3 -p 4

# 4. Add the Caddyfile block to your existing Caddyfile (see Caddyfile.example)

# 5. Start Vaultwarden
docker compose up -d

# 6. Visit https://vaultwarden.lockeinvestments.net and create the admin account
```

## Post-Deployment Security Steps

1. Log into the web vault as the admin
2. **Disable open registration:** `SIGNUPS_ALLOWED=false`
3. **Enable MFA enforcement** at the Organization level
4. Create Organizations for each team/department
5. Invite users via email (they set their own master passwords)
6. Use **Collections** to control credential access per organization

## Employee Offboarding

1. Admin panel → Organization → Users → **Revoke user**
2. That user loses access to all shared credentials immediately
3. No shared master passwords, no standing sessions — one click

## Backups

Backups use restic with encryption:

```bash
# Manual backup
./scripts/backup.sh

# Restore from snapshot
./scripts/restore.sh              # list snapshots
./scripts/restore.sh <snapshot_id>  # restore specific snapshot
```

For automated daily backups, add a cron job:

```
0 3 * * * cd /opt/vaultwarden && ./scripts/backup.sh >> /var/log/vw-backup.log 2>&1
```

## Files

| File | Purpose |
|------|---------|
| `compose.yaml` | Docker Compose service definition |
| `Caddyfile.example` | Caddy reverse proxy config example |
| `.env.example` | Environment variable template |
| `scripts/backup.sh` | Encrypted backup to restic |
| `scripts/restore.sh` | Restore from restic snapshot |

## Repository Structure

```
.env.example          ← Environment variable template (copy to .env)
Caddyfile.example     ← Caddy proxy config example
compose.yaml          ← Docker Compose service definition
.gitignore            ← excludes secrets, vault data, backups
scripts/
├── backup.sh         ← Encrypted backup script
└── restore.sh        ← Restore script
```

## License

Infrastructure configuration — MIT.
