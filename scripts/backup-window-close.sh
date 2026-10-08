#!/bin/bash
# Author: Patryk L. Jackowski
# From: "Decisions at Scale" - Succeedity Publishing
# Caution: educational sample code. Review, test, and verify in a sandbox.
# Do not run against production without understanding every command.
# Use at your own risk.
# =============================================================================
# Air Gap Backup Window — Close
# Disables the network interface after backup completion.
# Governance decision: the interface must return to DOWN state
# regardless of whether the backup succeeded. A failed backup
# does not justify leaving the interface exposed.
#
# Usage: ./backup-window-close.sh [--dry-run]
# Cron:  30 3 * * * /usr/local/sbin/backup-window-close.sh
# =============================================================================

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true
INTERFACE="${BACKUP_INTERFACE:-ens192}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

log "Air Gap Window — CLOSE"
log "Interface: $INTERFACE | Mode: $([ "$DRY_RUN" = true ] && echo 'DRY RUN' || echo 'LIVE')"

if [ "$DRY_RUN" = true ]; then
    log "[DRY RUN] Would disable $INTERFACE"
    exit 0
fi

ip link set "${INTERFACE}" down

if ip link show "${INTERFACE}" | grep -q "state DOWN"; then
    log "Interface $INTERFACE is DOWN — air gap restored"
else
    log "ERROR: Interface $INTERFACE failed to go down"
    exit 1
fi
