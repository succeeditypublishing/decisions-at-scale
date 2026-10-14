# Script Library

All twelve scripts support `--dry-run`. Run that first, every single time.

| Script | What it does |
|---|---|
| `bootstrap-server.sh` | Fresh-host hardening: SELinux stays enforcing, SSH keys only, default-deny nftables, automatic security updates, AIDE file integrity. |
| `harden-system.sh` | Kernel sysctl baseline: drop source-routed packets and ICMP redirects, reverse-path filtering, SYN cookies, ASLR, module lockdown. |
| `nftables-baseline.conf` | Default-deny ruleset. Only established/related traffic, loopback, rate-limited ICMP, and SSH are allowed in. |
| `wireguard-keygen.sh` | Generate a WireGuard keypair under a strict umask so private keys are not world-readable. |
| `airgap-backup.sh` | Orchestrate a backup window: open network, run backup, verify, close. Supports `--secondary`. |
| `backup-window-open.sh` | Bring the backup interface up at the start of the window. |
| `backup-window-close.sh` | Bring the backup interface down at the end, regardless of backup success. |
| `verify-backups.sh` | Verify Proxmox Backup Server snapshots and fail loudly on corruption. |
| `audit-permissions.sh` | Find world-writable files and directories under `/etc`, `/var`, `/home` (or paths you pass). |
| `migration-preflight.sh` | Ask the questions that matter before a migration: time sync, backups, disk, services. |
| `observability-baseline.sh` | Confirm the monitoring essentials are actually running, not just installed. |
| `update-motd.sh` | Write a one-line login banner instead of recomputing it on every login. |

## Defaults and environment variables

- `bootstrap-server.sh` — `sudo ./bootstrap-server.sh [--dry-run]`, targets AlmaLinux / RHEL / CentOS Stream 9.
- `backup-window-open.sh` / `backup-window-close.sh` — `BACKUP_INTERFACE` env var, defaults to `ens192`.
- `verify-backups.sh` — `PBS_REPOSITORY` and `PBS_FINGERPRINT` env vars.
- `nftables-baseline.conf` — test with `nft -c -f /etc/nftables.conf`, apply with `nft -f /etc/nftables.conf`.

## How to Test These Scripts

Start with the checks that change nothing, then move to the ones that can take a host offline.

Prerequisites: `bash` and `nft` (from the `nftables` package) for the static checks, plus `shellcheck` (optional), `wireguard-tools`, and `proxmox-backup-client` for the later steps.

1. **Static checks** — Run `bash -n` on every `.sh` file and `nft -c -f nftables-baseline.conf` for the firewall. Neither changes anything.
2. **Dry-run everything** — Run each script with `--dry-run` and read the preview before running it live.
3. **Read-only checks live** — `audit-permissions.sh`, `migration-preflight.sh`, and `observability-baseline.sh` modify nothing and are safe on a running host.
4. **Mutating scripts** — Snapshot a disposable AlmaLinux 9 VM, run `bootstrap-server.sh` and `harden-system.sh`, then reboot. `harden-system.sh` sets `kernel.modules_disabled = 1`, so reboot before loading any new kernel module.
5. **Backup scripts** — Point `PBS_PRIMARY` or `PBS_REPOSITORY` at a test Proxmox Backup Server, or mock `proxmox-backup-client` to prove the control flow.
6. **WireGuard** — Install `wireguard-tools`, run `wireguard-keygen.sh`, and confirm a `0600` key in `/etc/wireguard/`.

A throwaway AlmaLinux 9 VM with a snapshot covers everything except the Ubuntu-specific fallback in `observability-baseline.sh`.

This book uses nftables, not legacy iptables. nft is the default on RHEL 9 / AlmaLinux 9 / Ubuntu; if a tool still speaks iptables, use the `iptables-nft` backend so both share one kernel ruleset.

For a full step-by-step run on a real AlmaLinux 9 host, see [TESTING.md](../TESTING.md).

> **Caution:** educational sample code. Review, test, and verify in a sandbox before production use. Do not run against a live system without understanding every command. Use at your own risk.
