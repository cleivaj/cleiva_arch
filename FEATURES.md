# Features & Improvements

## ✅ Implemented (v2.0 - Interactive Edition)

### 🎨 User Experience
- **One-command installation**: Just run `./init.sh`
- **Interactive menus** using whiptail (JaKooLit-inspired)
- **Full auto mode**: Complete workflow from detection to script generation
- **Step-by-step mode**: Run each phase individually
- **Visual banners** and colored output
- **Progress feedback** at each step

### 📦 Package Management
- **Profile selection**:
  - Hyprland (full featured)
  - Minimal (base system only)
  - Custom (choose everything)
- **Development packages**:
  - Node.js + npm
  - MariaDB / PostgreSQL
  - Docker + docker-compose
  - VS Code (AUR)
- **Tools & Utilities**:
  - Neovim / Vim
  - Tmux
  - Firefox / Chromium
- **Smart deduplication**: No duplicate packages
- **Reason tracking**: Every package explains why it was selected

### 💾 Partition Management
- **Auto layout**: EFI/BIOS + swap (smart sizing) + root
- **Interactive editor**: Custom partitions with guided prompts
- **Manual mode**: Edit `output/layout.txt` directly
- **Multi-disk support**: Choose target disk when multiple detected
- **Flexible sizing**: Support for `rest`, GB sizes, or `auto` swap

### 🔍 Hardware Detection (11 modules)
- Firmware (UEFI/BIOS)
- CPU vendor (Intel/AMD microcode)
- RAM (smart swap sizing)
- GPU (AMD/NVIDIA/Intel drivers)
- Disk (type, size, rotation)
- Virtualization detection
- Battery (laptop detection)
- Bluetooth
- Network (WiFi + connectivity)
- Audio
- Timezone

### 🛡️ Safety Features
- **VM-only execution**: Install script refuses to run on bare metal
- **USB stick protection**: Never selects boot media
- **Removable media check**: Won't touch USB drives
- **Review before execution**: Shows full script before running
- **Non-destructive detection**: Never writes to disks

### 📊 Reporting
- **Markdown report**: `output/report.md` with full justification
- **Package validation**: Check against official repos
- **Missing package detection**: Identifies AUR-only packages
- **Facts summary**: All detected hardware in table format

### 🎯 Preset System
- **Reusable configurations**: Save your choices
- **Preset files**: `presets/developer.preset`, `presets/minimal.preset`
- **Environment variables**: Override any setting
- **Quick deployment**: `./init.sh --preset presets/developer.preset`

### 🧪 Testing
- **Test script**: `test_interactive.sh` validates all components
- **Modular design**: Each component testable independently
- **Output validation**: Checks generated files

## 🚧 Roadmap (Future Versions)

### v2.1 - Multi-Profile Support
- [ ] GNOME profile
- [ ] KDE Plasma profile
- [ ] i3 / Sway profile
- [ ] Gaming profile (Steam, Lutris, gamemode)
- [ ] Server profile (headless)

### v2.2 - Advanced GPU Selection
- [ ] Fine-grained NVIDIA driver selection (nvidia vs nvidia-open)
- [ ] Hybrid graphics support (laptops with iGPU + dGPU)
- [ ] PRIME configuration for NVIDIA Optimus
- [ ] AMD/Intel hybrid support

### v2.3 - Post-Install Configuration
- [ ] Dotfiles deployment
- [ ] Automatic service enablement
- [ ] User creation during install
- [ ] AUR helper installation (yay/paru)
- [ ] First-boot configuration wizard

### v2.4 - Network & Connectivity
- [ ] WiFi configuration during install
- [ ] Mirror selection optimization
- [ ] Parallel downloads configuration
- [ ] VPN setup options

### v2.5 - Advanced Features
- [ ] LUKS encryption support
- [ ] LVM configuration
- [ ] BTRFS subvolumes with snapshots
- [ ] Separate /home partition automation
- [ ] Swap file option (instead of partition)

### v2.6 - Developer Experience
- [ ] Language/framework profiles:
  - Python (pyenv, pipenv)
  - Node.js (nvm, yarn, pnpm)
  - Rust (rustup)
  - Go
  - Java (OpenJDK)
- [ ] Container runtime selection (Docker/Podman)
- [ ] IDE selection (VS Code, IntelliJ, etc.)

### v3.0 - Advanced Installer
- [ ] Live system installer (run from installed Arch)
- [ ] Dual-boot support
- [ ] Bootloader selection (GRUB/systemd-boot/rEFInd)
- [ ] Secure Boot support
- [ ] Multi-distribution support (EndeavourOS, Manjaro base)

## 💡 Ideas & Suggestions

### Community Requests
- [ ] TUI with arrow key navigation (alternative to whiptail)
- [ ] Web UI for configuration (generate script remotely)
- [ ] Docker image for testing
- [ ] Ansible playbook alternative
- [ ] Configuration backup/restore
- [ ] Update checker for packages
- [ ] Rollback functionality (Timeshift integration)

### Quality of Life
- [ ] Installation time estimation
- [ ] Bandwidth monitoring during install
- [ ] Locale selection menu
- [ ] Keyboard layout configuration
- [ ] Hostname customization dialog
- [ ] Root password prompt before script execution
- [ ] Installation log with timestamps

## 🤝 Contributing

Want to add a feature? Here's how:

1. Check the roadmap above
2. Open an issue describing your feature
3. Fork and create a feature branch
4. Implement with tests
5. Submit a PR

For detection modules: they must be independent, output `KEY=VALUE`, and handle missing commands gracefully.

For package profiles: add to `decide/packages.sh` with clear reasons for each package.

## 📝 Feature Request Template

```markdown
### Feature Name
**Category**: [Detection / Packages / Partitioning / UI / Safety]
**Priority**: [High / Medium / Low]

**Description**:
What feature would you like to see?

**Use Case**:
Why is this useful? Who would benefit?

**Implementation Ideas**:
Any thoughts on how this could work?
```

Submit feature requests as GitHub issues with the label `enhancement`.
