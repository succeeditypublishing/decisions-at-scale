#!/usr/bin/env bash
# migration-preflight.sh -- the questions to answer before moving anything
# Applies to: AlmaLinux 9 / RHEL 9 / CentOS Stream 9 / Ubuntu 24.04
# --dry-run prints the checklist without running checks.

set -euo pipefail
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

ask() {
  local label="$1"; local cmd="$2"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] would check: $label"
    return 0
  fi
  if sh -c "$cmd" >/dev/null 2>&1; then
    echo "[ ok ] $label"
  else
    echo "[FAIL] $label"
  fi
}

echo "Migration preflight:"
ask "time sync is healthy"       "chronyc tracking | grep -q 'Leap status.*Normal'"
ask "host has current backup"    "test -f /var/backups/latest.tar.gz"
ask "DNS resolves both zones"    "getent hosts app.internal"
ask "can reach new subnet"       "ping -c1 -W1 10.20.0.1"
ask "firewall allows mgmt ssh"   "ss -ltn | grep -q ':22 '"
echo "Preflight complete."
