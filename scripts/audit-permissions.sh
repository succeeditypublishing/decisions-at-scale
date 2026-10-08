#!/bin/bash
# Author: Patryk L. Jackowski
# From: "Decisions at Scale" - Succeedity Publishing
# Caution: educational sample code. Review, test, and verify in a sandbox.
# Do not run against production without understanding every command.
# Use at your own risk.
# =============================================================================
# Access Control Audit — Decisions at Scale
# Finds world-writable files and directories from Chapter 13.
#
# Usage: ./audit-permissions.sh [--dry-run] [path1 path2 ...]
# Default path: /etc /var /home
# =============================================================================

set -euo pipefail

DRY_RUN=false
ARGS=()

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        *) ARGS+=("$arg") ;;
    esac
done

if [ ${#ARGS[@]} -eq 0 ]; then
    PATHS=(/etc /var /home)
else
    PATHS=("${ARGS[@]}")
fi

log() { echo "[$(date '+%H:%M:%S')] $1"; }

log "Access Control Audit — Decisions at Scale"
log "Mode: $([ "$DRY_RUN" = true ] && echo 'DRY RUN' || echo 'LIVE')"
log "Scanning: ${PATHS[*]}"
echo ""

find "${PATHS[@]}" -type f -perm -002 -ls 2>/dev/null | while read -r line; do
    echo "WORLD-WRITABLE FILE: $line"
done

find "${PATHS[@]}" -type d -perm -002 -ls 2>/dev/null | while read -r line; do
    echo "WORLD-WRITABLE DIR:  $line"
done

FILE_COUNT=$(find "${PATHS[@]}" -type f -perm -002 2>/dev/null | wc -l)
DIR_COUNT=$(find "${PATHS[@]}" -type d -perm -002 2>/dev/null | wc -l)

echo ""
log "Results: $FILE_COUNT world-writable files, $DIR_COUNT world-writable directories"

if [ "$FILE_COUNT" -gt 0 ] || [ "$DIR_COUNT" -gt 0 ]; then
    log "ACTION REQUIRED: Review each finding. Document exceptions or fix."
    exit 1
else
    log "Clean — no world-writable items found."
fi
