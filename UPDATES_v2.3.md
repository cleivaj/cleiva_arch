# Updates v2.3 - In-Script Installation

## 🚀 New Feature: Run Installation from Menu

Now you can execute the installation script directly from the interactive menu!

## ✨ What's New

### 1. **Dynamic Menu**

The main menu now adapts based on whether an install script exists:

**Before generating script:**
```
1. 🚀 Full Auto Install
2. 🔍 Detect Hardware
...
8. 📝 Generate Install Script
9. 🧹 Clean Output Files
0. ❌ Exit
```

**After generating script:**
```
1. 🚀 Full Auto Install
2. 🔍 Detect Hardware
...
8. 📝 Generate Install Script
9. ▶️  Run Installation Script  ← NEW!
10. 🧹 Clean Output Files
0. ❌ Exit
```

### 2. **Interactive Post-Generation Menu**

After generating the install script, you now see:

```
╔═══════════════════════════════════════╗
║     Install Script Ready              ║
╠═══════════════════════════════════════╣
║ Script generated successfully!        ║
║                                       ║
║ What would you like to do?           ║
║                                       ║
║  » View the script                   ║
║  » Run the installation now          ║
║  » Return to main menu               ║
╚═══════════════════════════════════════╝
```

### 3. **Safe Installation Runner**

When you choose to run the installation:

#### Step 1: Final Confirmation
```
⚠️  FINAL CONFIRMATION

You are about to run the installation script!

⚠️  WARNING:
- This will partition and format disks
- This will install Arch Linux
- Only run inside a VM!

The script has safety checks and will refuse to run on:
- Real hardware (non-VM)
- Removable media (USB drives)

Do you want to proceed?

    <Yes>  <No>
```

#### Step 2: Live Installation Output
```
═══════════════════════════════════════
[ℹ] Starting installation...
[ℹ] Running: bash output/install.sh

<Full installation output here>
- Partitioning...
- Formatting...
- Installing packages...
- Configuring system...
- Installing bootloader...

═══════════════════════════════════════
```

#### Step 3: Completion Status

**On Success:**
```
╔═══════════════════════════════════════╗
║ ✅ Installation Complete              ║
╠═══════════════════════════════════════╣
║ Installation finished successfully!   ║
║                                       ║
║ Next steps:                           ║
║ 1. Reboot when ready: reboot         ║
║ 2. After reboot, run post-install:   ║
║    - wine-setup.sh                   ║
║    - steam-setup.sh                  ║
║    - hyprland-keyboard.sh            ║
║                                       ║
║ Enjoy your new Arch Linux system!    ║
╚═══════════════════════════════════════╝
```

**On Failure:**
```
╔═══════════════════════════════════════╗
║ ❌ Installation Failed                ║
╠═══════════════════════════════════════╣
║ Installation failed with exit code 1  ║
║                                       ║
║ Check the output above for errors.   ║
║                                       ║
║ Common issues:                        ║
║ - Not running in a VM                ║
║ - Disk is removable media            ║
║ - Network connection issues          ║
║ - Package download failures          ║
║                                       ║
║ Review error messages and try again. ║
╚═══════════════════════════════════════╝
```

## 🔄 New Workflow

### Option A: Full Auto + Run
```bash
./init.sh
→ Choose "1" (Full Auto Install)
→ Configure everything
→ Script generates
→ Choose "Run the installation now"
→ Confirm
→ Installation runs
→ Success!
```

### Option B: Generate + Run Later
```bash
./init.sh
→ Complete steps 1-8
→ Return to menu
→ Choose "9" (Run Installation Script)
→ Installation runs
```

### Option C: Generate + Manual Run
```bash
./init.sh
→ Complete steps 1-8
→ Choose "Return to main menu"
→ Exit
→ bash output/install.sh  # Manual
```

## 🛡️ Safety Features

### Built-in Protections

The runner includes:

1. **VM Check**
   - Refuses to run on real hardware
   - Uses `systemd-detect-virt`
   - Only runs in VMs (VirtualBox, QEMU, VMware, etc.)

2. **Removable Media Check**
   - Won't partition USB drives
   - Protects your installation media

3. **Final Confirmation**
   - Clear warning before execution
   - Lists all risks
   - Easy to cancel

4. **Exit Code Handling**
   - Detects installation failures
   - Shows specific error messages
   - Prevents false success reports

## 📊 Code Changes

### New Functions (lib/steps.sh)

```bash
step_generate()              # Updated with menu
run_install_script()         # New installation runner
```

### Updated Functions (init.sh)

```bash
main_menu()                  # Dynamic menu items
main()                       # Handles both menu states
```

## 🎯 Use Cases

### Case 1: Quick Test Install
```
Perfect for: Testing in VirtualBox
Workflow: Full Auto → Run → Done!
Time: ~20 minutes total
```

### Case 2: Review First
```
Perfect for: Cautious users
Workflow: Generate → View → Review → Run
Time: Add 5 minutes for review
```

### Case 3: Batch Processing
```
Perfect for: Multiple VMs
Workflow: Generate once → Copy script → Run multiple times
Time: Generate once, reuse many times
```

## 💡 Example Session

```bash
# Boot Arch ISO in VirtualBox
pacman -Sy git --noconfirm
git clone <repo>
cd arch_installer

# Start installer
./init.sh

# Menu appears
→ Choose "1" (Full Auto)

# Configure system
Hostname: myarch
Keyboard: es
Locale: es_ES.UTF-8
Timezone: Europe/Madrid

# Select profile
→ Hyprland

# Select extras
[X] firefox
[X] nodejs
[X] docker

# Auto partition
→ Auto

# Validation passed
✓ All packages exist

# Script generated!
→ Choose "Run the installation now"

# Confirm
→ Yes

# Watch installation
[Installing packages...]
[Configuring system...]
[Installing GRUB...]

# Success!
✓ Installation Complete

# Reboot
reboot

# Done! 🎉
```

## 🔍 Technical Details

### Exit Code Detection

```bash
bash output/install.sh
exit_code=$?

if [[ $exit_code -eq 0 ]]; then
    # Success handling
else
    # Error handling with specific messages
fi
```

### Menu State Management

```bash
# Check if script exists
if [[ -f output/install.sh ]]; then
    # Show "Run Install" option
else
    # Hide "Run Install" option
fi
```

### Output Preservation

- Installation output shown in real-time
- Scrollback available for review
- "Press Enter to continue" after completion
- Returns to menu cleanly

## ✅ Benefits

### User Experience
- ✅ No need to exit the script
- ✅ See installation progress live
- ✅ Clear success/failure indication
- ✅ Smooth workflow from start to finish

### Safety
- ✅ Multiple confirmation layers
- ✅ VM detection prevents accidents
- ✅ Clear warnings before execution
- ✅ Exit code validation

### Convenience
- ✅ One-stop shop for everything
- ✅ View script before running
- ✅ Run immediately or later
- ✅ Return to menu after install

## 🧪 Testing

```bash
# Test generation
./init.sh
→ Generate script
→ Choose "View"
✓ Script displays

# Test menu dynamic
ls output/install.sh
✓ Menu shows "Run Install" option

# Test runner (dry run)
# Note: Won't actually run on real hardware
./init.sh
→ Choose "9" (Run Install)
→ Confirm
✓ Safety check prevents execution on non-VM
```

## 📝 Files Modified

- ✅ `lib/steps.sh` - New `run_install_script()`
- ✅ `lib/steps.sh` - Updated `step_generate()`
- ✅ `init.sh` - Dynamic menu
- ✅ `init.sh` - Dual-state case handling

## 🎉 Summary

**Before:**
- ❌ Generate script
- ❌ Exit `init.sh`
- ❌ Run `bash output/install.sh` manually
- ❌ Disconnect between steps

**Now:**
- ✅ Generate script
- ✅ Choose action (View/Run/Exit)
- ✅ Run directly from menu
- ✅ Seamless workflow
- ✅ Live progress feedback
- ✅ Success/failure handling

**Result:**
- 🚀 Faster workflow
- 🛡️ Safer (more confirmations)
- 📊 Better feedback
- ✨ Professional UX
