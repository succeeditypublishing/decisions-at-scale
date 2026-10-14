#!/usr/bin/env bash
# observability-baseline.sh -- verify the monitoring essentials are live
# Applies to: AlmaLinux 9 / RHEL 9 / CentOS Stream 9 / Ubuntu 24.04
# Note: Ubuntu uses `chrony` and `prometheus-node-exporter` unit names;
#       RHEL-family uses `chronyd` and `node_exporter`.
# --dry-run prints what would be checked without changing anything.

set -euo pipefail
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

check() {
  local name="$1"; shift
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] would check: $name"
    return 0
  fi
  if "$@" >/dev/null 2>&1; then
    echo "[ ok ] $name"
  else
    echo "[FAIL] $name"
  fi
}

echo "Observability baseline:"
check "time daemon active"     sh -c 'systemctl is-active chronyd >/dev/null 2>&1 || systemctl is-active chrony >/dev/null 2>&1'
check "NTP is synchronized"    sh -c 'chronyc tracking | grep -q "Leap status.*Normal"'
check "metrics agent active"   sh -c 'systemctl is-active node_exporter >/dev/null 2>&1 || systemctl is-active prometheus-node-exporter >/dev/null 2>&1'
check "auditd is active"       systemctl is-active auditd
check "log shipper active"     sh -c 'systemctl is-active rsyslog >/dev/null 2>&1 || systemctl is-active syslog-ng >/dev/null 2>&1'
echo "Done."
