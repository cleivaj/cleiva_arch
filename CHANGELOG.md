# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - Interactive Edition - 2025-01-XX

### 🎉 Major Changes
- **Complete UI overhaul**: Interactive menus with whiptail
- **One-command installation**: `./init.sh` replaces multi-step workflow
- **Profile system**: Choose Hyprland, Minimal, or Custom
- **Extra package selection**: Add development tools interactively
- **Preset support**: Save and reuse configurations

### ✨ New Features

#### User Interface
- Interactive menu system with whiptail
- ASCII art banner
- Colored output with status indicators
- Full auto-install mode (all steps in one go)
- Step-by-step mode for granular control

#### Package Management
- Profile selection (Hyprland/Minimal/Custom)
- Interactive package picker with checkboxes
- Development packages:
  - Node.js + npm
  - MariaDB / PostgreSQL
  - Docker + docker-compose
  - VS Code
- Utilities: Neovim, Tmux, Firefox, Chromium
- Improved package reasons and documentation

#### Partition Management
- Interactive partition editor
- Auto/Custom/Manual modes
- Multi-disk selection dialog
- Visual partition plan display

#### Configuration
- Preset file system (`.preset` files)
- Environment variable overrides
- Reusable configurations

### 📚 Documentation
- **NEW**: `QUICKSTART.md` - 5-minute getting started guide
- **NEW**: `FEATURES.md` - Complete feature list and roadmap
- **NEW**: `CHANGELOG.md` - This file
- **UPDATED**: `README.md` - Comprehensive documentation
- **EXAMPLE**: `presets/developer.preset` - Development setup
- **EXAMPLE**: `presets/minimal.preset` - Minimal installation

### 🧪 Testing
- **NEW**: `test_interactive.sh` - Component validation script
- All 11 detection modules tested
- Package decision tree validated
- Partition generation verified

### 🔧 Improvements
- Better error handling
- More informative messages
- Package validation against official repos
- Missing package detection
- Better GPU driver detection
- Enhanced safety checks

### 🐛 Bug Fixes
- Fixed partition suffix detection for NVMe
- Improved disk candidate filtering
- Better handling of VM detection
- Fixed layout parsing edge cases

### 📝 Files Added
```
init.sh                      # Main interactive entry point
QUICKSTART.md                # Quick start guide
FEATURES.md                  # Feature list and roadmap
CHANGELOG.md                 # This file
test_interactive.sh          # Testing script
presets/developer.preset     # Developer preset example
presets/minimal.preset       # Minimal preset example
output/.gitkeep              # Preserve output directory
```

### 📝 Files Modified
```
README.md                    # Updated for v2.0
decide/packages.sh           # Profile support
.gitignore                   # Better output handling
```

---

## [1.0.0] - Educational Edition - 2024-XX-XX

### Initial Release
- Hardware detection (11 modules)
- Package decision tree
- Partition planning
- Install script generation
- Hyprland profile
- VM-only safety checks
- Markdown reporting
- Command-line interface

### Detection Modules
- Firmware (UEFI/BIOS)
- CPU (Intel/AMD)
- RAM
- GPU (AMD/NVIDIA/Intel)
- Disk (with USB filtering)
- Virtualization
- Battery
- Bluetooth
- Network
- Audio
- Timezone

### Decision Systems
- Package selection with reasoning
- Automatic driver selection
- Profile-based packages
- Deduplication logic

### Installation
- Partition with sgdisk
- Format (btrfs/ext4)
- Pacstrap base system
- GRUB bootloader
- Locale/timezone configuration
- User creation

---

## Versioning

This project uses [Semantic Versioning](https://semver.org/):
- **MAJOR**: Incompatible API/workflow changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

## Upgrade Guide

### From 1.x to 2.0

**Command Changes:**
```bash
# Old way (still works!)
./main.sh detect
./main.sh decide
./main.sh install

# New way (recommended)
./init.sh
# Choose option 1 (Full Auto)
```

**Configuration:**
- No breaking changes to `output/facts.txt` format
- New optional `PROFILE` and `EXTRA_PACKAGES` variables
- Existing scripts continue to work

**Migration:**
1. Pull latest changes
2. Run `./init.sh` for interactive mode
3. Or continue using `./main.sh` commands

No data migration needed. All existing workflows compatible.

---

## Future Releases

See [FEATURES.md](FEATURES.md) for the complete roadmap.

### Planned for v2.1
- GNOME profile
- KDE profile
- i3/Sway profile
- Gaming profile

### Planned for v2.2
- Fine-grained NVIDIA driver selection
- Hybrid graphics support
- Better GPU detection

### Planned for v3.0
- Dual-boot support
- Live system installer
- Secure Boot support

---

## Contributing

Want to see your feature in the next release? Check [FEATURES.md](FEATURES.md) and submit a PR!

Format: `[version] - Description - Date`
