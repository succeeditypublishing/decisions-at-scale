#!/bin/bash
# =============================================================================
# Backup Integrity Verification — Decisions at Scale
# Verifies PBS snapshots from Chapter 34.
# Run: daily via cron, alert on failure.
#
# Usage: ./verify-backups.sh [--dry-run] [--repository REPO]
# =============================================================================

set -euo pipefail

DRY_RUN=false
REPO="${PBS_REPOSITORY:-root@pam@localhost:prod-datastore}"
FINGERPRINT="${PBS_FINGERPRINT:-}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --repository) REPO="$2"; shift 2 ;;
        --fingerprint) FINGERPRINT="$2"; shift 2 ;;
        *) shift ;;
    esac
done

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

log "Backup Integrity Verification — Decisions at Scale"
log "Repository: $REPO"
log "Mode: $([ "$DRY_RUN" = true ] && echo 'DRY RUN' || echo 'LIVE')"

if [ "$DRY_RUN" = true ]; then
    log "[DRY RUN] Would verify snapshots in $REPO"
    exit 0
fi

export PROXMOX_OUTPUT_NO_BORDER=1 PROXMOX_OUTPUT_NO_HEADER=1
log "Fetching snapshot list..."
if ! SNAPLIST=$(proxmox-backup-client snapshot list \
    --repository "$REPO" \
    ${FINGERPRINT:+--fingerprint "$FINGERPRINT"} --output-format text 2>&1); then
    log "ERROR: Failed to list snapshots"
    printf '%s\n' "$SNAPLIST"
    exit 2
fi

printf '%s\n' "$SNAPLIST" | tail -5

LATEST=$(printf '%s\n' "$SNAPLIST" | awk '{print $1}' | tail -1)
if [ -z "$LATEST" ]; then
    log "ERROR: no snapshots found in repository"
    exit 3
fi

log "Verifying most recent snapshot: $LATEST"
if proxmox-backup-client restore "$LATEST" index.json - \
    --repository "$REPO" \
    ${FINGERPRINT:+--fingerprint "$FINGERPRINT"} > /dev/null 2>&1; then
    log "Integrity verified: $LATEST"
else
    log "ERROR: integrity check failed for $LATEST"
    exit 4
fi
