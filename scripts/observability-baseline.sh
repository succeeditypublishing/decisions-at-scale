#!/usr/bin/env bash
# Author: Patryk L. Jackowski
# From: "Decisions at Scale" - Succeedity Publishing
# Caution: educational sample code. Review, test, and verify in a sandbox.
# Do not run against production without understanding every command.
# Use at your own risk.
# observability-baseline.sh -- verify the monitoring essentials are live
# Applies to: AlmaLinux 9 / RHEL 9 / CentOS Stream 9 / Ubuntu 24.04
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
check "chronyd is active"      systemctl is-active chronyd
check "NTP is synchronized"    chronyc tracking
check "metrics agent active"   systemctl is-active node_exporter
check "auditd is active"       systemctl is-active auditd
check "log shipper active"     systemctl is-active rsyslog
echo "Done."
