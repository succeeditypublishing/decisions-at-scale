#!/bin/bash
# Author: Patryk L. Jackowski
# From: "Decisions at Scale" - Succeedity Publishing
# Caution: educational sample code. Review, test, and verify in a sandbox.
# Do not run against production without understanding every command.
# Use at your own risk.
# =============================================================================
# System Information Login Banner — Decisions at Scale
# Modernized from a legacy /etc/motd script.
# Writes a one-line summary to /etc/motd instead of recomputing
# it on every login.
#
# Usage: sudo ./update-motd.sh [--dry-run]
# =============================================================================

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

HOSTNAME="$(hostnamectl --static)"
CPU="$(lscpu | awk -F: '/Model name/ {gsub(/^[ \t]+/,"",$2); print $2}')"
MEM_TOTAL="$(free -h | awk '/^Mem:/ {print $2}')"
MEM_USED="$(free -h | awk '/^Mem:/ {print $3}')"
UPTIME="$(uptime -p | sed 's/^up //')"
USERS="$(who | wc -l)"

BANNER="$(printf '%s | %s | Memory %s used of %s | Up %s | %s users' \
    "$HOSTNAME" "$CPU" "$MEM_USED" "$MEM_TOTAL" "$UPTIME" "$USERS")"

if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would write: $BANNER"
else
    printf '%s\n' "$BANNER" > /etc/motd
    echo "Wrote /etc/motd: $BANNER"
fi
