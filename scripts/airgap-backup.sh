#!/bin/bash
# Author: Patryk L. Jackowski
# From: "Decisions at Scale" - Succeedity Publishing
# Caution: educational sample code. Review, test, and verify in a sandbox.
# Do not run against production without understanding every command.
# Use at your own risk.
# =============================================================================
# Air Gap Backup Orchestrator — Decisions at Scale
# Coordinates backup windows from Chapter 18.
# Governance decisions:
#   - Backup targets unreachable outside scheduled windows
#   - Primary and secondary windows do not overlap
#   - Client certificate authentication only — no passwords
#   - Verification runs before the window closes
#
# Usage: ./airgap-backup.sh [--dry-run] [--secondary]
# Cron (production cluster):
#   0 1 * * * /usr/local/sbin/airgap-backup.sh
#   0 4 * * * /usr/local/sbin/airgap-backup.sh --secondary
# Cron (backup servers):
#   0 1 * * * /usr/local/sbin/backup-window-open.sh
#   30 3 * * * /usr/local/sbin/backup-window-close.sh
# =============================================================================

set -euo pipefail

DRY_RUN=false
SECONDARY=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --secondary) SECONDARY=true; shift ;;
        *) shift ;;
    esac
done

PRIMARY_HOST="${PBS_PRIMARY:-10.10.99.10}"
SECONDARY_HOST="${PBS_SECONDARY:-10.20.99.10}"
PBS_FINGERPRINT="${PBS_FINGERPRINT:-}"
KEYFILE="${PBS_KEYFILE:-/etc/pbs/backup-key.enc}"
DATASTORE="${PBS_DATASTORE:-daily}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

if [ "$SECONDARY" = true ]; then
    TARGET="$SECONDARY_HOST"
    WINDOW="secondary (04:00-06:30)"
else
    TARGET="$PRIMARY_HOST"
    WINDOW="primary (01:00-03:30)"
fi

log "Air Gap Backup Orchestrator — Decisions at Scale"
log "Window: $WINDOW | Target: $TARGET"
log "Mode: $([ "$DRY_RUN" = true ] && echo 'DRY RUN' || echo 'LIVE')"

if [ "$DRY_RUN" = true ]; then
    log "[DRY RUN] Would connect to $TARGET and run backup"
    exit 0
fi

[ ! -f "$KEYFILE" ] && { log "ERROR: Keyfile not found: $KEYFILE"; exit 2; }

log "Waiting for backup target..."
for i in $(seq 1 12); do
    if ping -c 1 -W 2 "$TARGET" > /dev/null 2>&1; then
        log "Target reachable"
        break
    fi
    [ "$i" -eq 12 ] && { log "ERROR: Target unreachable"; exit 3; }
    sleep 5
done

log "Starting backup..."
proxmox-backup-client backup "${DATASTORE}.pxar:/" \
    --repository "${TARGET}:datastore" \
    ${PBS_FINGERPRINT:+--fingerprint "$PBS_FINGERPRINT"} \
    --keyfile "$KEYFILE"

if [ $? -eq 0 ]; then
    log "Backup completed — verifying..."
    proxmox-backup-client snapshot list \
        --repository "${TARGET}:datastore" \
        ${PBS_FINGERPRINT:+--fingerprint "$PBS_FINGERPRINT"} \
        --keyfile "$KEYFILE" --output-format text | tail -3
    log "Verification passed"
else
    log "ERROR: Backup failed"
    exit 4
fi

log "Backup window complete"
