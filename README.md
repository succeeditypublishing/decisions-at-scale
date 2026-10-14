# Decisions at Scale — Companion Scripts

Companion code for **Decisions at Scale: The Cybersecurity Architect's Guide to Survivable Systems** by Patryk L. Jackowski.

These are the twelve hardening, networking, and backup scripts referenced in the book. They were generalized from production patterns and cleaned up so you can read them, adapt them, and test them on your own lab gear.

> **Read this before you run anything.**
> These are educational samples, not a turnkey production installer. Every environment is different, and the wrong firewall rule or backup-window setting can take a machine offline. Review every line, run with `--dry-run` first, and test in a sandbox before it goes near a live system. You are responsible for every command they run. Use at your own risk.

## The scripts

| Script | What it does |
|---|---|
| `bootstrap-server.sh` | Baseline OS hardening for a fresh AlmaLinux / RHEL 9 host |
| `harden-system.sh` | Kernel sysctl hardening and service lockdown |
| `nftables-baseline.conf` | Default-deny inbound firewall ruleset |
| `wireguard-keygen.sh` | Generate a WireGuard keypair with a strict umask |
| `airgap-backup.sh` | Orchestrate the air-gap backup window |
| `backup-window-open.sh` | Bring the backup interface up for the window |
| `backup-window-close.sh` | Take the backup interface down, no matter what |
| `verify-backups.sh` | Verify Proxmox Backup Server snapshots and alert on failure |
| `audit-permissions.sh` | List world-writable files and directories |
| `migration-preflight.sh` | Pre-migration checklist |
| `observability-baseline.sh` | Confirm chronyd, syslog, and core metrics are live |
| `update-motd.sh` | Write a one-line hardened MOTD banner |

See [`scripts/README.md`](scripts/README.md) for full details and `--dry-run` behavior on each.

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

For a full step-by-step run on a real AlmaLinux 9 host, see [TESTING.md](TESTING.md).

## Author

Patryk L. Jackowski — [linkedin.com/in/patryk-jackowski](https://www.linkedin.com/in/patryk-jackowski)

## Publisher

Succeedity Publishing — [succeeditypublishing.com](https://succeeditypublishing.com)

## License

The scripts are MIT-licensed. The book itself is not open source and is not included here.
