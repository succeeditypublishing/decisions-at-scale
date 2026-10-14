# Testing on a Real AlmaLinux 9 Host

These scripts are educational samples. Run them in this order on a disposable AlmaLinux 9 VM with a snapshot, never on production. Revert the snapshot when you are done.

## 0. Prepare a disposable VM

Create a clean AlmaLinux 9 minimal VM, take a snapshot, and do all of this there.

## 1. Get the scripts

```bash
git clone https://github.com/succeeditypublishing/decisions-at-scale.git
cd decisions-at-scale/scripts
```

Or unzip `Decisions-at-Scale-Scripts.zip` and `cd` into the extracted folder.

## 2. Install prerequisites

```bash
sudo dnf install -y epel-release
sudo dnf install -y nftables wireguard-tools bash procps-ng iproute iputils chrony aide dnf-automatic
sudo dnf install -y ShellCheck   # optional but recommended, from EPEL
```

The backup scripts expect `proxmox-backup-client`, which ships from the Proxmox Backup Server repository, not EPEL. If you don't have a PBS, skip live backup testing and mock the command (see Phase 7).

## Phase 1 — Static checks (changes nothing)

```bash
for f in *.sh; do
  bash -n "$f" && echo "OK   $f" || echo "FAIL $f"
done

sudo nft -c -f nftables-baseline.conf
```

Expected: every `.sh` prints `OK`, and `nft -c` prints nothing (no `syntax error`). Optionally:

```bash
shellcheck -S warning *.sh
```

## Phase 2 — Dry-run everything (changes nothing)

```bash
for f in harden-system.sh bootstrap-server.sh backup-window-open.sh \
         backup-window-close.sh verify-backups.sh airgap-backup.sh \
         wireguard-keygen.sh update-motd.sh migration-preflight.sh \
         observability-baseline.sh audit-permissions.sh; do
  echo "=== $f --dry-run ==="
  sudo bash "$f" --dry-run
done
```

Expected: each prints `[DRY RUN] ...` or `Would ...` and exits `0`, applying no changes.

## Phase 3 — Read-only live checks (safe on a running host)

```bash
sudo bash audit-permissions.sh
sudo bash migration-preflight.sh
sudo bash observability-baseline.sh
```

Expected:

- `audit-permissions.sh` reports world-writable files/dirs and exits `0` if clean, `1` if it found findings (by design).
- `migration-preflight.sh` and `observability-baseline.sh` print `[ ok ]` / `[FAIL]` per check. Failures on a bare test VM are expected for missing backups.

## Phase 4 — Mutating scripts (snapshot first)

### 4a. Harden the system

```bash
sudo bash harden-system.sh
```

Expected: writes `/etc/sysctl.d/99-hardening.conf`, applies it, and verifies five parameters. It sets `kernel.modules_disabled = 1`, so reboot before loading any new kernel modules:

```bash
sudo reboot
```

After reboot, confirm:

```bash
sudo sysctl net.ipv4.conf.all.accept_source_route \
  net.ipv4.conf.all.accept_redirects \
  net.ipv4.conf.all.rp_filter \
  net.ipv4.tcp_syncookies \
  kernel.randomize_va_space
```

All five should match the values in the script.

### 4b. Bootstrap a fresh server (optional, dedicated VM)

`bootstrap-server.sh` is for a clean install, not an already-configured host. On a fresh VM:

```bash
sudo bash bootstrap-server.sh
```

It prompts for an administrator username, installs packages, enforces SELinux, hardens SSH, installs nftables, enables `dnf-automatic`, and initializes AIDE. Replace the placeholder SSH key in the script before running it for real.

## Phase 5 — Firewall apply (after harden or bootstrap)

```bash
sudo nft -f nftables-baseline.conf
sudo nft list ruleset
```

Or make it persistent:

```bash
sudo cp nftables-baseline.conf /etc/nftables.conf
sudo systemctl enable --now nftables
```

Expected: `nft list ruleset` shows the `inet filter` table with `policy drop` on input/forward.

## Phase 6 — WireGuard keys

```bash
sudo bash wireguard-keygen.sh
ls -l /etc/wireguard/private.key /etc/wireguard/public.key
```

Expected: both keys exist and are mode `0600`. The public key prints to stdout.

## Phase 7 — Backup scripts (real PBS or mock)

**With a real Proxmox Backup Server:**

```bash
export PBS_REPOSITORY='root@pam@YOUR_PBS_IP:datastore'
export PBS_FINGERPRINT='YOUR_SERVER_FINGERPRINT'
sudo bash verify-backups.sh
sudo bash airgap-backup.sh --dry-run   # then live, with a keyfile
```

**Without PBS (mock the command):**

Create a fake `proxmox-backup-client` earlier in `$PATH` that prints plausible output and exits `0`. This proves the control flow without a real server.

For the window scripts, pick a test interface and use dry-run:

```bash
BACKUP_INTERFACE=ens192 sudo bash backup-window-open.sh --dry-run
BACKUP_INTERFACE=ens192 sudo bash backup-window-close.sh --dry-run
```

Do not run these live against your management interface.

## When finished

Revert the VM snapshot. Nothing survives, which is the point.
