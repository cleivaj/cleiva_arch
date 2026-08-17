# arch_installer

**Interactive & Educational** Arch Linux installer: detects your hardware, lets you
choose packages and partitions through friendly menus, and generates a complete
installation script. It never touches your disks — the generated script is meant
to run **inside a VM (QEMU/VirtualBox)**, and it refuses to run anywhere else.

The goal is to understand how each piece works under the hood, with a user-friendly
interface inspired by JaKooLit's installer:

```
detect hardware  →  choose packages  →  configure layout  →  generate install
      (read)           (decide)              (plan)              (act)
```

## 🚀 Quick Start (One Command)

```bash
git clone <your-repo> && cd arch_installer
./init.sh
```

That's it! The interactive menu guides you through everything.

## How it works

| Folder | Role |
|---|---|
| `detect/` | Standalone modules that read the system and emit facts as `KEY=VALUE` (11 modules: firmware, cpu, ram, virt, battery, bluetooth, net, audio, disk, gpu, timezone) |
| `decide/` | Decisions: `packages.sh` (facts → packages + reason), `partition.sh` (facts → partition layout), `install.sh` (everything → install script) |
| `lib/` | Helpers: logging (`common.sh`) and package search on the official API (`api.sh`) |
| `output/` | Generated results: facts, package list, report, partition plan, install script |

Each `detect/` script can be run on its own to see what it detects:

```bash
./detect/gpu.sh      # → GPU_VENDOR=nvidia (or amd / intel / unknown)
./detect/disk.sh     # → DISK_NAME=nvme0n1 (never the USB boot stick)
./detect/timezone.sh # → TIMEZONE=Europe/Lisbon
```

## 📋 Interactive Menu Features

The `./init.sh` script provides:

1. **🚀 Full Auto Install** - Complete workflow from detection to script generation
2. **🔍 Detect Hardware** - Scan your system (11 detection modules)
3. **📦 Configure Packages** - Choose profile (Hyprland/minimal/custom) + extras:
   - Development: Node.js, npm, MariaDB, PostgreSQL
   - Tools: Docker, VS Code, Neovim, Tmux
   - Browsers: Firefox, Chromium
4. **💾 Configure Partitions** - Auto, custom interactive, or manual layout
5. **📊 View Report** - See detection results and package justifications
6. **🧪 Validate Packages** - Check all packages exist in official repos
7. **📝 Generate Install Script** - Create the final `output/install.sh`
8. **🧹 Clean Output** - Remove generated files

## 🎯 Usage Modes

### Interactive Mode (Recommended)
```bash
./init.sh
# Follow the menus - that's it!
```

### Manual Mode (Advanced)
You can still use the original commands:

```bash
./main.sh detect       # hardware facts → output/facts.txt
./main.sh decide       # decision tree → output/packages.txt + report.md
./main.sh search hyprland   # search packages on the archlinux.org API
./main.sh check        # validate the list against the official repos (needs network)
./main.sh partition    # partition plan → output/partition.txt
./main.sh install      # full install script → output/install.sh
./main.sh all          # detect + decide + check
./main.sh clean        # remove generated output files
```

### Typical Workflow in VirtualBox/QEMU

1. **Boot Arch ISO in VM**
2. **Clone the repo:**
   ```bash
   pacman -Sy git --noconfirm
   git clone https://github.com/YOUR_USER/arch_installer.git
   cd arch_installer
   ```
3. **Run interactive installer:**
   ```bash
   ./init.sh
   ```
4. **Choose "Full Auto Install"** and follow prompts
5. **Review the generated script:**
   ```bash
   less output/install.sh
   ```
6. **Execute it:**
   ```bash
   bash output/install.sh
   ```

The report (`output/report.md`) tells you **why** each package was chosen.
Example: `GPU_VENDOR=nvidia` → `nvidia-utils` "GPU NVIDIA => drivers + libGL".

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

Every rule is **"if (fact) then (decision) because (reason)"**:

```bash
case "$GPU_VENDOR" in
  nvidia) add nvidia-utils "GPU NVIDIA => drivers + libGL" ;;
esac
```

### Packages (`decide/packages.sh`)

- Base: `base base-devel linux git nano networkmanager sudo`
- CPU: Intel → `intel-ucode`, AMD → `amd-ucode`
- GPU (bare metal only; VMs get generic `mesa`):
  AMD → `mesa vulkan-radeon`, NVIDIA → `nvidia-utils`, Intel → `mesa
  vulkan-intel`, unknown → `mesa` fallback
- Bluetooth present → `bluez bluez-utils`
- Laptop (battery) → `brightnessctl tlp`
- Audio → `pipewire pipewire-pulse wireplumber`
- Profile Hyprland → hyprland, waybar, kitty, grim, slurp, fonts, ...
- Duplicates are impossible: packages live in an associative array (`PACKAGES`), one reason per package.

### Partition plan (`decide/partition.sh`)

- `FIRMWARE=uefi` → EFI 512M + swap + root; `bios` → BIOS boot 1M + swap + root
- Swap: ≤2G RAM → 2x, ≤8G → 1x, >8G → half (always at least 2G)
- SSD/NVMe → `btrfs`, HDD → `ext4`
- Partition names get a `p` only when the disk needs it (`nvme0n1p1`, `sda1`)

### Install script (`decide/install.sh`)

- `output/install.sh` is generated, **never executed here**. It:
  1. Refuses to run outside a VM (`systemd-detect-virt`) and on removable
     media — your USB install stick is untouchable.
  2. Partitions with `sgdisk`, formats (`btrfs`/`ext4`/`vfat`), mounts.
  3. `pacstrap`s the **decided package list** (from `output/packages.txt`)
     plus `linux-firmware`, `grub`, `efibootmgr` (UEFI only) and
     `btrfs-progs` (btrfs only).
  4. Configures locale and timezone (`locale-gen`, `locale.conf` — the
     timezone comes from the `TIMEZONE` fact), hostname and services
     (NetworkManager, plus `bluetooth`/`tlp` when detected).
  5. Installs GRUB (x86_64-efi for UEFI, i386-pc + bios_grub for BIOS).
  6. Asks for a root password and creates a sudo user (wheel).

  Overrides: `TIMEZONE`, `LOCALE`, `HOST_NAME` come from
  `output/facts.txt` or the environment (defaults: `UTC`, `en_US.UTF-8`,
  `arch`).

## Detection details worth knowing

- `detect/disk.sh` **never picks the USB stick you booted from**: it
  excludes the boot device (found via `findmnt /run/archiso/bootmnt` or the
  `ARCH_*` label), USB buses and removable disks (RM flag), plus
  zram/ram/loop devices. It emits `DISK_CANDIDATES` (comma-separated) and
  picks the first as default `DISK_NAME`; if several remain, `partition`/
  `install` ask you interactively.
- `detect/gpu.sh` scans **all** display controllers and prefers the discrete
  GPU (NVIDIA > AMD > Intel), so hybrid laptops detect correctly.
- Every module degrades gracefully: if a command or sysfs path is missing it
  prints a safe default (`unknown`, `no`, `0`...) instead of failing.

## Testing in QEMU

The full installation **must** be tested in a VM, never on your machine:

```bash
# 1. Boot the Arch ISO in QEMU (UEFI firmware → OVMF)
qemu-system-x86_64 -enable-kvm -m 4G -cdrom archlinux.iso -boot d \
    -bios /usr/share/ovmf/x64/OVMF.fd     # or: -drive if=pflash=...

# 2. Inside the ISO
git clone <your-repo> && cd arch_installer
./main.sh all
./main.sh install
bash output/install.sh   # review it first!
```

## 🎨 Screenshots & Examples

**Interactive Menu:**
```
╔═══════════════════════════════════════════════════════╗
║     Arch Hyprland Automated Installer                ║
╚═══════════════════════════════════════════════════════╝

1) 🚀 Full Auto Install
2) 🔍 Detect Hardware Only
3) 📦 Configure Packages & Profile
...
```

**Package Selection:**
- Choose profile: Hyprland / Minimal / Custom
- Pick extras: Node.js, Docker, MariaDB, VS Code...
- See justification: Every package explains why it was selected

**Generated Report:**
See `output/report.md` for hardware detection results and package decisions with full reasoning.

## 📚 Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Get started in 5 minutes
- **[FEATURES.md](FEATURES.md)** - Full feature list and roadmap
- **[TODO.md](TODO.md)** - Original development plan (educational)
- **README.md** (this file) - Complete reference

## 🗺️ Roadmap

See [FEATURES.md](FEATURES.md) for the complete roadmap.

**Next up:**
- v2.1: Multi-profile support (GNOME, KDE, i3)
- v2.2: Advanced GPU configuration
- v2.3: Post-install configuration wizard
- v3.0: Dual-boot support

## 🤝 Contributing

Contributions welcome! See [FEATURES.md](FEATURES.md) for ideas.

1. Fork the repository
2. Create feature branch
3. Make changes with tests
4. Submit pull request

## 📜 License

Educational project - feel free to use, modify, and learn from it.

## 🙏 Credits & Inspiration

- [JaKooLit/Arch-Hyprland](https://github.com/JaKooLit/Arch-Hyprland) - Inspiration for interactive UI
- [archinstall](https://github.com/archlinux/archinstall) - Official installer reference
- [Arch Wiki](https://wiki.archlinux.org/) - Comprehensive documentation
- [Hyprland](https://hyprland.org/) - Amazing Wayland compositor

## 📖 References

- [Arch Wiki: Installation guide](https://wiki.archlinux.org/title/Installation_guide)
- [Arch Wiki: pacman](https://wiki.archlinux.org/title/Pacman)
- [archlinux.org package API](https://wiki.archlinux.org/title/DeveloperWiki:Package_search)
- [Hyprland Wiki](https://wiki.hyprland.org/)