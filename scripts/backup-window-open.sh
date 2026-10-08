#!/bin/bash
# Author: Patryk L. Jackowski
# From: "Decisions at Scale" - Succeedity Publishing
# Caution: educational sample code. Review, test, and verify in a sandbox.
# Do not run against production without understanding every command.
# Use at your own risk.
# =============================================================================
# Air Gap Backup Window — Open
# Enables the network interface for the backup window.
# Runs locally on the backup server via cron at 01:00.
# Governance decision: the backup server exists on the network for
# exactly the duration of the backup window. Outside that window,
# the interface is physically down — no network path exists.
#
# Usage: ./backup-window-open.sh [--dry-run]
# Cron:  0 1 * * * /usr/local/sbin/backup-window-open.sh
# =============================================================================

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true
INTERFACE="${BACKUP_INTERFACE:-ens192}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

log "Air Gap Window — OPEN"
log "Interface: $INTERFACE | Mode: $([ "$DRY_RUN" = true ] && echo 'DRY RUN' || echo 'LIVE')"

if [ "$DRY_RUN" = true ]; then
    log "[DRY RUN] Would enable $INTERFACE"
    exit 0
fi

ip link set "${INTERFACE}" up
sleep 5

if ip addr show "${INTERFACE}" | grep -q "state UP"; then
    log "Interface $INTERFACE is UP — backup window open"
else
    log "ERROR: Interface $INTERFACE failed to come up"
    exit 1
fi
