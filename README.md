# arch_installer

**Educational** Arch Linux installer: detects your hardware and decides which
packages an installation with Hyprland would need. It doesn't install
anything — the first version is just **detection + decision** so you
understand how each piece works under the hood.

## How it works

An installer isn't magic. It's this:

```
detect hardware  →  decide packages  →  run the installation
      (read)              (think)              (act)
```

| Folder | Role |
|---|---|
| `detect/` | Standalone modules that read the system and emit facts as `KEY=VALUE` |
| `decide/` | Decision tree: maps facts → packages, with the reason for each one |
| `lib/` | Helpers: logging (`common.sh`) and package search on the official API (`api.sh`) |
| `output/` | Generated results: facts, package list and explained report |

Each `detect/` script can be run on its own to see what it detects:

```bash
./detect/gpu.sh     # → GPU_VENDOR=nvidia (or amd / intel / unknown)
./detect/virt.sh    # → VIRT=none (or kvm, virtualbox, wsl...)
```

## Usage

```bash
./main.sh detect        # hardware facts → output/facts.txt
./main.sh decide        # decision tree → output/packages.txt + report.md
./main.sh search hyprland   # search packages on the archlinux.org API
./main.sh check         # validate the list against the official repos (needs network)
./main.sh all           # detect + decide + check
./main.sh clean         # remove generated output files
```

The report (`output/report.md`) is the important part: it tells you **why**
each package was chosen. Example: `GPU_VENDOR=nvidia` → `nvidia-utils`
"NVIDIA GPU → utilities and libGL".

## How package searches work

There are two levels, and this project uses the second one:

1. **`pacman -Ss <name>`** — searches the local package database (only
   useful inside an installed system, after `pacman -Sy`).
2. **Official archlinux.org API** — `lib/api.sh` queries
   `https://archlinux.org/packages/search/json/?q=<name>` and checks whether
   the package exists in the official repos and in which repo/version. That's
   what `./main.sh check` uses to validate the list before installing.

The JSON is parsed with `grep` on purpose: for checking existence that's
enough. The right tool for real JSON is `jq`.

## Decision tree philosophy

In `decide/packages.sh` every rule is **"if (fact) then (package) because
(reason)"**:

```bash
case "$GPU_VENDOR" in
  nvidia) add nvidia-utils "NVIDIA GPU → utilities and libGL" ;;
esac
```

Adding new knowledge = adding a `case`. Examples of rules already included:

- Intel/AMD CPU → `intel-ucode` / `amd-ucode`
- NVIDIA/AMD/Intel GPU → corresponding drivers
- VM detected (`systemd-detect-virt`) → generic drivers, not specific ones
- Bluetooth present → `bluez bluez-utils`
- Laptop (battery) → `brightnessctl tlp`
- SSD/NVMe → btrfs recommendation; HDD → ext4 recommendation

## Roadmap (upcoming versions)

1. **Partitioning**: use `FIRMWARE` (uefi/bios), `DISK_*` and `RAM_GB` to
   generate the partition table (EFI + root, swap size).
2. **Real installation**: `pacstrap`, `arch-chroot`, `mkinitcpio`,
   bootloader (systemd-boot for UEFI, GRUB for BIOS), user, locale.
3. **Profiles**: besides Hyprland, support GNOME/KDE/i3, and profiles
   (dev, gaming, minimal).
4. **Finer detection**: choose between `nvidia` and `nvidia-open` based on
   the exact GPU model (readable from the PCI device ID).

To test the full installation without breaking your system: **QEMU**.
```bash
# from the Arch ISO mounted in a VM
qemu-system-x86_64 -enable-kvm -cdrom archlinux.iso -boot d -m 4G
```

## References

- [archinstall](https://github.com/archlinux/archinstall) — official
  installer (Python): the biggest real decision tree that exists.
- [Arch Wiki: Installation guide](https://wiki.archlinux.org/title/Installation_guide)
- [Arch Wiki: pacman](https://wiki.archlinux.org/title/Pacman)
- [archlinux.org package API](https://wiki.archlinux.org/title/DeveloperWiki:Package_search)
