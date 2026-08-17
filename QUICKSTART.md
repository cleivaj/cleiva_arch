# Quick Start Guide

## 🎯 For the Impatient

```bash
# In your Arch ISO (VM only!)
pacman -Sy git --noconfirm
git clone https://github.com/YOUR_USERNAME/arch_installer.git
cd arch_installer
./init.sh
# Choose "1" for Full Auto Install
# Follow the prompts
# Review the generated script
bash output/install.sh
```

Done! Your system will be installed.

---

## 📖 Step-by-Step (Recommended for First Time)

### Prerequisites
- A VM (VirtualBox, QEMU, VMware)
- Arch Linux ISO booted
- Internet connection

### Step 1: Get the Installer

```bash
# Install git if not already available
pacman -Sy git --noconfirm

# Clone the repository
git clone https://github.com/YOUR_USERNAME/arch_installer.git
cd arch_installer
```

### Step 2: Run Interactive Installer

```bash
./init.sh
```

You'll see a menu like this:
```
╔═══════════════════════════════════════════════════════╗
║            Arch Hyprland Installer Menu              ║
╚═══════════════════════════════════════════════════════╝

1) 🚀 Full Auto Install
2) 🔍 Detect Hardware Only
3) 📦 Configure Packages & Profile
4) 💾 Configure Disk Partitions
5) 📊 View Detection Report
6) 🧪 Validate Package List
7) 📝 Generate Install Script
8) 🧹 Clean Output Files
9) ❌ Exit
```

### Step 3: Choose Your Path

#### Option A: Full Auto (Easiest)
1. Choose `1` - Full Auto Install
2. Select profile:
   - **Hyprland**: Complete tiling WM setup (recommended)
   - **Minimal**: Base system only
   - **Custom**: Choose everything yourself
3. Select extra packages (SPACE to select):
   - Development: Node.js, MariaDB, Docker
   - Tools: Neovim, Tmux, VS Code
   - Browsers: Firefox, Chromium
4. Choose partition layout:
   - **Auto**: EFI + swap + root (recommended)
   - **Custom**: Interactive editor
   - **Manual**: Edit `output/layout.txt`
5. Done! Script is generated.

#### Option B: Step by Step
1. Choose `2` - Detect Hardware
   - Scans your system
   - Saves to `output/facts.txt`
2. Choose `3` - Configure Packages
   - Select profile and extras
3. Choose `4` - Configure Partitions
   - Set up disk layout
4. Choose `6` - Validate (optional but recommended)
   - Checks all packages exist
5. Choose `7` - Generate Install Script
   - Creates `output/install.sh`

### Step 4: Review the Script

**IMPORTANT**: Always review before running!

```bash
less output/install.sh
# or
cat output/install.sh
```

Check:
- ✓ Correct disk selected
- ✓ Partition sizes make sense
- ✓ Packages look right
- ✓ Locale/timezone correct

### Step 5: Execute Installation

```bash
bash output/install.sh
```

The script will:
1. ✓ Check it's running in a VM (safety)
2. ✓ Partition the disk
3. ✓ Format filesystems
4. ✓ Install base system + packages
5. ✓ Configure locale/timezone
6. ✓ Install GRUB bootloader
7. ✓ Ask for root password
8. ✓ Create your user account

Time: ~15-30 minutes depending on internet speed

### Step 6: Reboot & Enjoy

```bash
reboot
```

Login and start Hyprland:
```bash
Hyprland
```

---

## 🎓 What Gets Installed?

### Base System (Always)
- `base`, `base-devel`, `linux`
- `git`, `nano`, `sudo`
- `networkmanager`
- CPU microcode (AMD/Intel)
- GPU drivers (auto-detected)

### Hyprland Profile
- Hyprland compositor
- Waybar (status bar)
- Kitty (terminal)
- Wofi (app launcher)
- All dependencies for Wayland

### Your Extras
Whatever you selected:
- Development: Node.js, databases
- Tools: editors, multiplexers
- Browsers: Firefox, Chromium

### Plus Auto-Configured
- Audio: Pipewire + Wireplumber
- Bluetooth (if detected)
- Power management (laptops)
- Network: WiFi + Ethernet

---

## 🔧 Customization

### Use a Preset

```bash
# Create or edit a preset
nano presets/mysetup.preset

# Use it
./init.sh --preset presets/mysetup.preset
```

### Edit Package List Manually

```bash
# After detection, before generation
nano output/packages.txt
# Add or remove packages
```

### Custom Partition Layout

```bash
# Create custom layout
cat > output/layout.txt << EOF
[swap] linux-swap 8G
/home btrfs 100G
/ btrfs rest
EOF

# Then generate install script
./main.sh install
```

---

## ❓ Common Questions

### Q: Can I run this on my real hardware?
**A: NO!** The install script refuses to run outside VMs. This is by design for safety.

### Q: What if I want different packages?
**A:** Choose "Custom" profile or edit `output/packages.txt` before generating the script.

### Q: Can I install alongside Windows?
**A:** Not yet. This installer assumes a clean disk. Dual-boot support is planned for v3.0.

### Q: What if a package doesn't exist?
**A:** The validator will warn you. Check if it's in AUR or if the name changed.

### Q: How do I add more swap?
**A:** Use custom partition layout or edit `output/layout.txt`.

### Q: Can I use this for servers?
**A:** Yes! Choose "Minimal" profile and skip desktop packages.

---

## 🆘 Troubleshooting

### "No disk detected"
- Check VM has a virtual disk attached
- Ensure it's not the USB boot device

### "Package X not found"
- Run `./main.sh check` to validate
- Package might be in AUR (not supported yet)
- Package name might have changed

### "Permission denied on ./init.sh"
```bash
chmod +x init.sh
```

### "Script fails in VM"
- Ensure 3D acceleration is enabled
- Check VM has enough RAM (2GB minimum)
- Verify internet connection

### Installation hangs at pacstrap
- Check internet connection
- Try different mirror
- Increase VM RAM

---

## 📚 Advanced Usage

### Command-Line Mode

```bash
# Traditional workflow
./main.sh detect
./main.sh decide
./main.sh check
./main.sh partition
./main.sh install
bash output/install.sh
```

### Environment Variables

```bash
# Override defaults
LOCALE="es_ES.UTF-8" \
TIMEZONE="Europe/Madrid" \
HOST_NAME="myarch" \
./main.sh install
```

### Preset Files

Create `presets/developer.preset`:
```bash
PROFILE="hyprland"
EXTRA_PACKAGES="nodejs npm docker code neovim"
TIMEZONE="Europe/Lisbon"
```

Use it:
```bash
./init.sh --preset presets/developer.preset
```

---

## 🎉 What's Next?

After installation:
1. Configure Hyprland: `~/.config/hypr/hyprland.conf`
2. Install AUR helper: `yay` or `paru`
3. Add more software
4. Customize dotfiles
5. Enjoy your new system!

---

## 💬 Need Help?

- Check `output/report.md` for what was detected
- Review logs in `Install-Logs/` (if any errors)
- Read full README.md for details
- Open an issue on GitHub

---

**Happy Installing! 🚀**
