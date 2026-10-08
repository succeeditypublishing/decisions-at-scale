#!/bin/bash
# Author: Patryk L. Jackowski
# From: "Decisions at Scale" - Succeedity Publishing
# Caution: educational sample code. Review, test, and verify in a sandbox.
# Do not run against production without understanding every command.
# Use at your own risk.
# =============================================================================
# System Hardening Baseline — Decisions at Scale
# Applies kernel hardening parameters from Chapter 2.
# Governance decisions implemented:
#   - Source-routed packets are not trusted (accept_source_route = 0)
#   - ICMP redirects are not accepted (accept_redirects = 0)
#   - Reverse-path filtering prevents IP spoofing (rp_filter = 1)
#   - SYN cookies prevent TCP SYN flood DoS (tcp_syncookies = 1)
#   - ASLR is enforced at maximum (randomize_va_space = 2)
#   - Core dumps from setuid binaries are disabled (suid_dumpable = 0)
#   - Kernel module loading is disabled post-boot (modules_disabled = 1)
#
# Usage: ./harden-system.sh [--dry-run]
# Supported: AlmaLinux 8/9, RHEL 8/9, CentOS 8/9, Ubuntu 20.04/22.04/24.04
# =============================================================================

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# Distribution detection
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="$ID"
    VERSION="$VERSION_ID"
else
    echo "ERROR: Cannot detect distribution. /etc/os-release not found."
    exit 1
fi

SYSCTL_CONF="/etc/sysctl.d/99-hardening.conf"
BACKUP="${SYSCTL_CONF}.bak.$(date +%Y%m%d%H%M%S)"

log() { echo "[$(date '+%H:%M:%S')] $1"; }
verify_param() {
    local param="$1" expected="$2"
    local actual
    actual=$(sysctl -n "$param" 2>/dev/null || echo "unknown")
    if [ "$actual" != "$expected" ]; then
        log "WARNING: $param = $actual (expected $expected)"
        return 1
    fi
}

log "System Hardening Baseline — Decisions at Scale"
log "Distribution: $DISTRO $VERSION"
log "Mode: $([ "$DRY_RUN" = true ] && echo 'DRY RUN (no changes)' || echo 'LIVE')"
echo ""

# Backup existing configuration
if [ "$DRY_RUN" = false ] && [ -f "$SYSCTL_CONF" ]; then
    cp "$SYSCTL_CONF" "$BACKUP"
    log "Backup saved to $BACKUP"
fi

# Write configuration
if [ "$DRY_RUN" = false ]; then
    cat > "$SYSCTL_CONF" << 'SYSCTL_EOF'
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.log_martians = 1
kernel.randomize_va_space = 2
fs.suid_dumpable = 0
kernel.modules_disabled = 1
SYSCTL_EOF
    sysctl --system > /dev/null 2>&1
    log "Configuration written to $SYSCTL_CONF"
else
    log "[DRY RUN] Would write hardening parameters to $SYSCTL_CONF"
    cat "$SYSCTL_CONF" 2>/dev/null || echo "  (file does not exist yet)"
fi

# Verification
echo ""
log "Verifying parameters..."
FAILS=0
verify_param net.ipv4.conf.all.accept_source_route 0 || ((FAILS++))
verify_param net.ipv4.conf.all.accept_redirects 0 || ((FAILS++))
verify_param net.ipv4.conf.all.rp_filter 1 || ((FAILS++))
verify_param net.ipv4.tcp_syncookies 1 || ((FAILS++))
verify_param kernel.randomize_va_space 2 || ((FAILS++))

if [ $FAILS -eq 0 ]; then
    log "All parameters verified OK"
else
    log "WARNING: $FAILS parameter(s) not at expected values"
fi

[ "$DRY_RUN" = true ] && log "DRY RUN complete — no changes applied"
