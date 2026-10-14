#!/bin/bash
# =============================================================================
# Air Gap Backup Orchestrator — Decisions at Scale
# Coordinates backup windows from Chapter 35.
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
if BACKUP_OUT=$(proxmox-backup-client backup "root.pxar:/" \
    --repository "${TARGET}:${DATASTORE}" \
    ${PBS_FINGERPRINT:+--fingerprint "$PBS_FINGERPRINT"} \
    --keyfile "$KEYFILE" 2>&1); then
    printf '%s\n' "$BACKUP_OUT" | tail -3
    SNAPSHOT=$(printf '%s\n' "$BACKUP_OUT" | sed -n 's/^Starting backup: *//p' | head -1)
    if [ -n "$SNAPSHOT" ]; then
        log "Verifying snapshot $SNAPSHOT (index restore test)..."
        if proxmox-backup-client restore "$SNAPSHOT" index.json - \
            --repository "${TARGET}:${DATASTORE}" \
            ${PBS_FINGERPRINT:+--fingerprint "$PBS_FINGERPRINT"} \
            --keyfile "$KEYFILE" > /dev/null 2>&1; then
            log "Integrity verified for $SNAPSHOT"
        else
            log "ERROR: integrity check failed for $SNAPSHOT"
            exit 5
        fi
    else
        log "WARNING: could not determine snapshot name — list snapshots manually"
    fi
else
    log "ERROR: Backup failed"
    printf '%s\n' "$BACKUP_OUT" | tail -5
    exit 4
fi

log "Backup window complete"
