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

## Author

Patryk L. Jackowski — [linkedin.com/in/patryk-jackowski](https://www.linkedin.com/in/patryk-jackowski)

## Publisher

Succeedity Publishing — [succeeditypublishing.com](https://succeeditypublishing.com)

## License

The scripts are MIT-licensed. The book itself is not open source and is not included here.
