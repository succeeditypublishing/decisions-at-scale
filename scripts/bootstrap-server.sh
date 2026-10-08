#!/bin/bash
# Author: Patryk L. Jackowski
# From: "Decisions at Scale" - Succeedity Publishing
# Caution: educational sample code. Review, test, and verify in a sandbox.
# Do not run against production without understanding every command.
# Use at your own risk.
# =============================================================================
# Server Bootstrap and Hardening — Decisions at Scale
# Modernized from a legacy CentOS install script.
# Governance decisions implemented:
#   - SELinux stays enforcing (never disabled)
#   - SSH rejects root and password auth; keys only
#   - Default-deny nftables ruleset, not iptables
#   - Automatic security updates via dnf-automatic
#   - AIDE initialized for file integrity monitoring
#
# Usage: sudo ./bootstrap-server.sh [--dry-run]
# Target: AlmaLinux 9 / RHEL 9 / CentOS Stream 9
# =============================================================================

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

log() { echo "[$(date '+%H:%M:%S')] $1"; }
run() {
    if [ "$DRY_RUN" = true ]; then
        log "[DRY RUN] $*"
    else
        log "RUN: $*"
        "$@"
    fi
}

log "Server Bootstrap — Decisions at Scale"
log "Mode: $([ "$DRY_RUN" = true ] && echo 'DRY RUN' || echo 'LIVE')"

# --- Base packages and update ---
run dnf install -y epel-release
run dnf install -y vim lsof wget chrony aide dnf-automatic
run dnf update -y

# --- SELinux: keep enforcing ---
run setenforce 1
run sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

# --- Time and services ---
run systemctl enable --now chronyd
run systemctl enable --now sshd

# --- SSH hardening ---
cat > /tmp/sshd_hardening.conf << 'SSHD'
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowGroups sshusers
MaxAuthTries 3
LoginGraceTime 30
SSHD
if [ "$DRY_RUN" = false ]; then
    cat /tmp/sshd_hardening.conf >> /etc/ssh/sshd_config
    systemctl restart sshd
else
    log "[DRY RUN] Would append SSH hardening to /etc/ssh/sshd_config"
fi

# --- Administrator account (key is a placeholder) ---
read -r -p "Administrator username: " ADMIN_USER
if [ "$DRY_RUN" = false ]; then
    groupadd -f sshusers
    useradd "$ADMIN_USER"
    usermod -a -G wheel,sshusers "$ADMIN_USER"
    mkdir -p "/home/$ADMIN_USER/.ssh"
    echo "ssh-ed25519 AAAA... replace-with-your-key $ADMIN_USER@workstation" \
        > "/home/$ADMIN_USER/.ssh/authorized_keys"
    chmod 700 "/home/$ADMIN_USER/.ssh"
    chmod 600 "/home/$ADMIN_USER/.ssh/authorized_keys"
    chown -R "$ADMIN_USER:$ADMIN_USER" "/home/$ADMIN_USER/.ssh"
else
    log "[DRY RUN] Would create $ADMIN_USER with sshusers group and a placeholder key"
fi

# --- nftables default-deny ---
run nft flush ruleset
cat > /tmp/nftables.conf << 'NFT'
table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        iif lo accept
        ct state established,related accept
        tcp dport 22 accept
        log prefix "bootstrap-input-drop: " limit rate 10/minute
    }
    chain forward {
        type filter hook forward priority 0; policy drop;
    }
    chain output {
        type filter hook output priority 0; policy accept;
    }
}
NFT
if [ "$DRY_RUN" = false ]; then
    cp /tmp/nftables.conf /etc/sysconfig/nftables.conf
    systemctl enable --now nftables
else
    log "[DRY RUN] Would install /etc/sysconfig/nftables.conf and enable nftables"
fi

# --- Automatic security updates ---
if [ "$DRY_RUN" = false ]; then
    sed -i 's/^apply_updates.*/apply_updates = yes/' /etc/dnf/automatic.conf
    systemctl enable --now dnf-automatic.timer
else
    log "[DRY RUN] Would enable dnf-automatic.timer"
fi

# --- File integrity monitoring ---
run aide --init
if [ "$DRY_RUN" = false ]; then
    mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
fi

log "Bootstrap complete."
[ "$DRY_RUN" = true ] && log "DRY RUN — no changes applied."
