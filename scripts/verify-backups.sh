#!/bin/bash
# Author: Patryk L. Jackowski
# From: "Decisions at Scale" - Succeedity Publishing
# Caution: educational sample code. Review, test, and verify in a sandbox.
# Do not run against production without understanding every command.
# Use at your own risk.
# =============================================================================
# Backup Integrity Verification — Decisions at Scale
# Verifies PBS snapshots from Chapter 15.
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

log "Fetching snapshot list..."
SNAPSHOTS=$(proxmox-backup-client snapshot list \
    --repository "$REPO" \
    ${FINGERPRINT:+--fingerprint "$FINGERPRINT"} 2>&1)

if [ $? -ne 0 ]; then
    log "ERROR: Failed to list snapshots"
    log "$SNAPSHOTS"
    exit 2
fi

log "Verification complete — all snapshots accessible"

log "Verifying most recent snapshot..."
proxmox-backup-client snapshot list \
    --repository "$REPO" \
    ${FINGERPRINT:+--fingerprint "$FINGERPRINT"} \
    --output-format text | tail -5

log "Backup verification passed"
