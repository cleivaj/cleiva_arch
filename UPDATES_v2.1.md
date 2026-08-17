# Updates v2.1 - Multimedia & Gaming Support

## 🎮 New Features Added

### 📦 New Selectable Packages

#### File Manager (Now Included by Default!)
- **Thunar** - GTK file manager perfect for Hyprland
  - `thunar` - Main file manager
  - `thunar-volman` - Removable device management
  - `tumbler` - Thumbnail generation
  - `thunar-archive-plugin` - Archive support
  - `file-roller` - Archive manager GUI
  - `gvfs` - Virtual filesystem (trash, network shares)
  - `gvfs-mtp` - Android phone support
- **Image Viewer**: `imv` - Fast Wayland image viewer

#### Gaming & Compatibility
- **Wine** - Windows application compatibility
  - `wine` - Main Wine package
  - `wine-mono` - .NET Framework support
  - `wine-gecko` - Internet Explorer support
  - `winetricks` - Easy configuration tool
  - `lib32-mesa` - 32-bit graphics
  - `lib32-vulkan-icd-loader` - 32-bit Vulkan
  - Auto-detects GPU and adds appropriate lib32 drivers:
    - AMD: `lib32-vulkan-radeon`
    - NVIDIA: `lib32-nvidia-utils`
    - Intel: `lib32-vulkan-intel`

- **Steam** - Gaming platform
  - `steam` - Valve's gaming client
  - `lib32-mesa` - 32-bit graphics for games
  - `lib32-vulkan-icd-loader` - 32-bit Vulkan
  - Auto-detects GPU for lib32 drivers

#### Multimedia
- **VLC** - Media player with codec pack
  - `vlc` - VLC media player
  - `ffmpeg` - Multimedia framework
  - `x264` - H.264 codec
  - `x265` - H.265/HEVC codec
  - `libva-mesa-driver` - Hardware video acceleration
  - `libvdpau-va-gl` - VDPAU acceleration

- **GIMP** - Image editor
  - `gimp` - GNU Image Manipulation Program
  - `gimp-help-en` - English documentation

#### Development (Enhanced)
- **Docker** - Now enables systemd service automatically
- **File Managers** - Thunar recommended for Hyprland

### 🔧 Automatic Configuration

#### Multilib Repository
- Automatically enabled when installing:
  - Wine
  - Steam
  - Any lib32-* package
- Added to `/etc/pacman.conf` during installation
- No manual intervention required

#### Service Management
- **NetworkManager** - Always enabled
- **Bluetooth** - Enabled if detected
- **TLP** - Enabled on laptops
- **Docker** - Enabled if Docker is selected

### 📝 Post-Install Scripts

New helper scripts for first-boot configuration:

#### `postinstall/wine-setup.sh`
- Enables multilib (if not done)
- Installs additional 32-bit libraries
- Creates Wine prefix (~/.wine)
- Initializes Wine configuration
- Provides winetricks usage examples

#### `postinstall/steam-setup.sh`
- Enables multilib (if not done)
- Installs Steam Runtime dependencies
- Configures Proton for Windows games
- Provides gaming optimization tips

### 🎨 Updated Menu

New menu layout with 17 selectable packages:
```
1. Thunar (file manager) ← RECOMMENDED
2. Node.js
3. npm
4. MariaDB
5. PostgreSQL
6. Docker
7. Docker Compose
8. VS Code
9. Firefox
10. Chromium
11. Wine
12. Steam
13. VLC
14. GIMP
15. Vim
16. Neovim
17. Tmux
```

### 📚 New Presets

#### `presets/gaming.preset`
- Hyprland profile
- Steam + Wine + VLC + browsers
- Large /home partition (200GB) for games

#### `presets/multimedia.preset`
- Hyprland profile
- GIMP + VLC + Firefox
- For content creators and editors

## 🔄 Changes to Existing Features

### Hyprland Profile (Updated)
Now includes by default:
- ✅ Thunar file manager + plugins
- ✅ imv image viewer
- ✅ All previous packages

Total packages: **39** (was 33)

### Install Script Generator
- Detects Wine/Steam/lib32 packages
- Automatically adds multilib repository config
- Enables Docker service if selected
- Better heredoc handling in chroot

## 📊 Package Count Breakdown

### Base System: 7 packages
- base, base-devel, linux, git, nano, networkmanager, sudo

### Hardware Drivers: 4-6 packages
- CPU microcode (AMD/Intel)
- GPU drivers (AMD/NVIDIA/Intel)
- Bluetooth (if detected)
- Laptop tools (if detected)

### Audio: 3 packages
- pipewire, pipewire-pulse, wireplumber

### Hyprland Profile: 25 packages
- Compositor + utilities
- Thunar + file management stack
- Fonts and themes

### User Selected: 0-50+ packages
- Depends on selections
- Wine adds ~10 packages
- Steam adds ~5 packages
- VLC adds ~7 packages

## 🎯 Use Cases

### Developer Workstation
```bash
Select: thunar, nodejs, npm, mariadb, docker, code, neovim, firefox
Result: ~45 packages
```

### Gaming Setup
```bash
Select: steam, wine, vlc, firefox, chromium
Result: ~55 packages
```

### Multimedia Studio
```bash
Select: gimp, vlc, firefox
Result: ~48 packages
```

### Minimal Desktop
```bash
Profile: hyprland
No extras
Result: 39 packages (with file manager)
```

## 🚀 Testing

All changes tested:
- ✅ Detection modules work
- ✅ Package selection expanded
- ✅ Multilib detection works
- ✅ Install script generates correctly
- ✅ Service management updated
- ✅ Post-install scripts created

Run tests:
```bash
./test_interactive.sh
```

## 📖 Documentation Updates

Updated files:
- `init.sh` - New package options
- `decide/packages.sh` - Thunar in Hyprland profile
- `decide/install.sh` - Multilib + Docker service
- `presets/` - New gaming and multimedia presets
- `postinstall/` - Wine and Steam setup scripts

## 🎉 Summary

**What's New:**
- File manager included by default (Thunar)
- Gaming support (Wine + Steam)
- Multimedia apps (VLC + GIMP)
- Automatic multilib configuration
- Post-install helper scripts
- 3 new presets

**Package Count:**
- Base Hyprland: 39 packages (↑6 from v2.0)
- With all extras: 70+ packages

**User Experience:**
- One less decision (file manager included)
- Gaming ready out of the box
- Post-install helpers reduce manual work
- More preset options

## 🔮 Next Up (v2.2)

- AUR helper installation (yay/paru)
- Fine-grained NVIDIA driver selection
- Hybrid GPU configuration
- More desktop environments (GNOME, KDE)
