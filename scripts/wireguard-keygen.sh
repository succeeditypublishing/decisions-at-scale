#!/bin/bash
# Author: Patryk L. Jackowski
# From: "Decisions at Scale" - Succeedity Publishing
# Caution: educational sample code. Review, test, and verify in a sandbox.
# Do not run against production without understanding every command.
# Use at your own risk.
# =============================================================================
# WireGuard Key Generator — Decisions at Scale
# Generates keypair from Chapter 3 with strict umask.
#
# Usage: ./wireguard-keygen.sh [--dry-run] [--peer NAME]
# =============================================================================

set -euo pipefail

DRY_RUN=false
PEER_NAME=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --peer) PEER_NAME="$2"; shift 2 ;;
        *) shift ;;
    esac
done

log() { echo "[$(date '+%H:%M:%S')] $1"; }

log "WireGuard Key Generator — Decisions at Scale"
log "Mode: $([ "$DRY_RUN" = true ] && echo 'DRY RUN' || echo 'LIVE')"

if [ "$DRY_RUN" = true ]; then
    log "[DRY RUN] Would generate keys in /etc/wireguard/"
    exit 0
fi

umask 077
mkdir -p /etc/wireguard

PRIVATE_KEY=$(wg genkey)
PUBLIC_KEY=$(echo "$PRIVATE_KEY" | wg pubkey)

if [ -n "$PEER_NAME" ]; then
    KEYFILE="/etc/wireguard/${PEER_NAME}.key"
    echo "$PRIVATE_KEY" > "$KEYFILE"
    chmod 600 "$KEYFILE"
    log "Keys generated for peer: $PEER_NAME"
    log "Private key: $KEYFILE (0600)"
    log "Public key:  $PUBLIC_KEY"
else
    echo "$PRIVATE_KEY" > /etc/wireguard/private.key
    echo "$PUBLIC_KEY" > /etc/wireguard/public.key
    chmod 600 /etc/wireguard/private.key /etc/wireguard/public.key
    log "Keys generated in /etc/wireguard/"
    log "Public key: $PUBLIC_KEY"
fi
