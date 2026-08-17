# Updates v2.2 - System Configuration & Localization

## 🌍 New Features Added

### ⚙️ Interactive System Configuration

Now you can configure all system settings through interactive menus:

#### 1. **Hostname Configuration**
- Set custom computer name
- Default: `arch`
- Input box with validation
- Saved to `output/facts.txt` as `HOST_NAME`

#### 2. **Keyboard Layout Selection**
- 12 common keyboard layouts:
  - `us` - US English (default)
  - `es` - Spanish
  - `pt` - Portuguese
  - `br` - Brazilian Portuguese
  - `uk` - UK English
  - `de` - German
  - `fr` - French
  - `it` - Italian
  - `ru` - Russian
  - `jp` - Japanese
  - `latam` - Latin American Spanish
  - `dvorak` - Dvorak layout
- Configured in:
  - Console: `/etc/vconsole.conf`
  - Hyprland: `~/.config/hypr/hyprland.conf`

#### 3. **Locale Selection**
- 10 common system locales:
  - `en_US.UTF-8` - English US (default)
  - `es_ES.UTF-8` - Spanish (Spain)
  - `pt_PT.UTF-8` - Portuguese (Portugal)
  - `pt_BR.UTF-8` - Portuguese (Brazil)
  - `en_GB.UTF-8` - English UK
  - `de_DE.UTF-8` - German
  - `fr_FR.UTF-8` - French
  - `it_IT.UTF-8` - Italian
  - `ru_RU.UTF-8` - Russian
  - `ja_JP.UTF-8` - Japanese
- Affects system language and formats

#### 4. **Timezone Selection**
- **Smart default**: Auto-detected from hardware
- Option to keep detected or change
- 14 common timezones:
  - UTC (Universal)
  - Europe: Lisbon, Madrid, London, Paris, Berlin, Moscow
  - Americas: New York, Chicago, Denver, Los Angeles, São Paulo, Mexico City
  - Asia: Tokyo
- Updates `/etc/localtime` during install

### 🎯 New Menu Structure

```
Main Menu:
1. 🚀 Full Auto Install (6 steps now)
2. 🔍 Detect Hardware Only
3. ⚙️  Configure System (NEW!)
4. 📦 Configure Packages & Profile
5. 💾 Configure Disk Partitions
6. 📊 View Detection Report
7. 🧪 Validate Package List
8. 📝 Generate Install Script
9. 🧹 Clean Output Files
0. ❌ Exit
```

### 📝 Updated Full Auto Workflow

Now includes 6 steps (was 5):

1. **Detect Hardware** - Scan system
2. **Configure System** - NEW! Hostname, keyboard, locale, timezone
3. **Configure Packages** - Profile and extras
4. **Configure Partitions** - Disk layout
5. **Validate Packages** - Check repos
6. **Generate Install Script** - Create installer

### 🔧 Configuration Summary Screen

After system configuration, shows:
```
Configuration set:

Hostname: myarch
Keyboard: es
Locale: es_ES.UTF-8
Timezone: Europe/Madrid

These settings will be applied during installation.
```

### 📊 Enhanced Reports

`output/report.md` now includes:

```markdown
## System Configuration

| Setting | Value |
|---|---|
| Hostname | myarch |
| Locale | es_ES.UTF-8 |
| Keyboard | es |
| Timezone | Europe/Madrid |

## Detected Hardware
...
```

### 🛠️ Post-Install Script

#### `postinstall/hyprland-keyboard.sh`
- Automatically configures Hyprland keyboard layout
- Matches console keyboard selection
- Adds input section if missing
- Updates existing configuration
- Provides examples for:
  - Multiple layouts (e.g., `us,es`)
  - Layout switching (Alt+Shift)
  - Variant options (nodeadkeys)

Usage:
```bash
# After first boot and login
~/arch_installer/postinstall/hyprland-keyboard.sh
```

## 🔄 Install Script Changes

### New Configuration Applied

During installation, the script now:

1. **Sets keyboard layout** in console:
   ```bash
   echo "KEYMAP=es" > /etc/vconsole.conf
   ```

2. **Configures locale**:
   ```bash
   echo "es_ES.UTF-8 UTF-8" > /etc/locale.gen
   locale-gen
   echo "LANG=es_ES.UTF-8" > /etc/locale.conf
   ```

3. **Sets timezone**:
   ```bash
   ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
   hwclock --systohc
   ```

4. **Sets hostname**:
   ```bash
   echo "myarch" > /etc/hostname
   ```

### Environment Variables

You can still override via environment:
```bash
LOCALE="pt_BR.UTF-8" \
KEYMAP="br" \
TIMEZONE="America/Sao_Paulo" \
HOST_NAME="meuarch" \
./main.sh install
```

## 📚 Documentation Updates

### QUICKSTART.md
- Updated workflow to show 6 steps
- Added system configuration examples
- Documented keyboard/locale selection

### Files Modified
- `init.sh` - New `step_system_config()` function
- `decide/install.sh` - Uses `KEYMAP` variable
- `output/report.md` - Shows system config
- Menu updated to 10 options (was 9)

### Files Added
- `postinstall/hyprland-keyboard.sh` - Keyboard setup

## 🎯 Use Cases

### Spanish User
```
Hostname: servidor
Keyboard: es
Locale: es_ES.UTF-8
Timezone: Europe/Madrid
```

### Portuguese (Brazil) User
```
Hostname: meupc
Keyboard: br
Locale: pt_BR.UTF-8
Timezone: America/Sao_Paulo
```

### Developer (US)
```
Hostname: devbox
Keyboard: us
Locale: en_US.UTF-8
Timezone: America/New_York
```

### Multi-Language Setup
After install, edit `~/.config/hypr/hyprland.conf`:
```
input {
    kb_layout = us,es
    kb_options = grp:alt_shift_toggle
}
```

## ✅ Testing

All changes tested:
- ✅ System configuration menu works
- ✅ Keyboard selection persists
- ✅ Locale selection applied correctly
- ✅ Timezone updates properly
- ✅ Hostname sets correctly
- ✅ Report shows configuration
- ✅ Install script includes settings

Run tests:
```bash
./test_interactive.sh
# Still passes with 39 packages
```

## 🎉 Summary

**What's New:**
- Complete system localization support
- Interactive keyboard/locale/timezone selection
- Auto-detection with manual override
- Hyprland keyboard post-install script
- Enhanced reporting with config summary

**User Experience:**
- No more hardcoded US-only defaults
- One-stop configuration in step 2
- Smart defaults from detection
- Easy to change if auto-detect wrong

**Workflow:**
- 6-step process (was 5)
- All settings configurable
- Preview before installation
- Post-install helpers for fine-tuning

## 🔮 Next Up (v2.3)

- Display manager selection (SDDM/GDM/LightDM)
- AUR helper installation (yay/paru)
- User creation during config phase
- Network configuration wizard
