#!/usr/bin/env bash
# Installation steps module

# Step 1: Detect hardware
step_detect() {
    echo -e "${INFO} Detecting hardware..."
    mkdir -p output
    
    for f in detect/*.sh; do
        [[ -f "$f" ]] || continue
        bash "$f" 2>/dev/null || true
    done | sort > output/facts.txt
    
    if [[ -s output/facts.txt ]]; then
        echo -e "${OK} Hardware detection complete"
        return 0
    else
        echo -e "${ERROR} Hardware detection failed"
        return 1
    fi
}

# Step 2: System configuration
step_system_config() {
    if [[ ! -f output/facts.txt ]]; then
        whiptail --title "Error" --msgbox "Hardware facts not found. Run detection first." 8 60
        return 1
    fi
    
    source output/facts.txt
    
    # Load menu functions
    if ! source lib/menus/system_config.sh; then
        whiptail --title "Error" --msgbox "Failed to load system configuration menu." 8 60
        return 1
    fi
    
    # Hostname
    local hostname
    hostname=$(menu_select_hostname)
    if [[ -z "$hostname" ]]; then
        hostname="arch"
    fi
    echo "HOST_NAME=$hostname" >> output/facts.txt
    
    # Keyboard
    local kb_layout
    kb_layout=$(menu_select_keyboard)
    if [[ -z "$kb_layout" ]]; then
        kb_layout="us"
    fi
    echo "KEYMAP=$kb_layout" >> output/facts.txt
    
    # Locale
    local locale
    locale=$(menu_select_locale)
    if [[ -z "$locale" ]]; then
        locale="en_US.UTF-8"
    fi
    echo "LOCALE=$locale" >> output/facts.txt
    
    # Timezone
    local detected_tz="${TIMEZONE:-UTC}"
    local tz_choice
    tz_choice=$(menu_select_timezone "$detected_tz")
    if [[ -z "$tz_choice" ]]; then
        tz_choice="$detected_tz"
    fi
    sed -i "s|^TIMEZONE=.*|TIMEZONE=$tz_choice|" output/facts.txt
    
    # User configuration
    local username user_password root_password
    
    # Ask for username
    username=$(menu_select_user)
    if [[ -n "$username" ]]; then
        echo "USERNAME=$username" >> output/facts.txt
        
        # Ask for user password
        user_password=$(menu_select_user_password)
        if [[ -n "$user_password" ]]; then
            # Store hashed password (more secure than plaintext)
            echo "USER_PASSWORD=$user_password" >> output/facts.txt
        fi
    fi
    
    # Ask for root password
    root_password=$(menu_select_root_password)
    if [[ -n "$root_password" ]]; then
        echo "ROOT_PASSWORD=$root_password" >> output/facts.txt
    fi
    
    # Summary
    show_system_config_summary "$hostname" "$kb_layout" "$locale" "$tz_choice"
    
    return 0
}

# Step 3: Package selection
step_packages() {
    if [[ ! -f output/facts.txt ]]; then
        whiptail --title "Error" --msgbox "Hardware facts not found. Run detection first." 8 60
        return 1
    fi
    
    source output/facts.txt
    
    # Base profile selection
    local profile
    profile=$(whiptail --title "Select Desktop Profile" \
        --menu "Choose your desktop environment:" 15 70 3 \
        "hyprland" "Hyprland (Wayland tiling compositor)" \
        "minimal" "Minimal (base system only)" \
        "custom" "Custom (choose packages manually)" \
        3>&1 1>&2 2>&3)
    
    [[ -z "$profile" ]] && return 1
    echo "PROFILE=$profile" >> output/facts.txt
    
    # Extra packages selection
    source lib/menus/packages.sh
    local extras
    extras=$(menu_select_extra_packages)
    
    # Save extra packages
    if [[ -n "$extras" ]]; then
        extras=$(echo "$extras" | tr -d '"' | tr '\n' ' ')
        echo "EXTRA_PACKAGES=\"$extras\"" >> output/facts.txt
    fi
    
    # Run package decision tree (this defines the 'add' function)
    source decide/packages.sh
    build_packages
    
    # Add extra packages (now 'add' function is available)
    add_extra_packages_to_tree "$extras"
    
    # Write packages
    for p in "${!PACKAGES[@]}"; do
        echo "$p"
    done | sort > output/packages.txt
    
    # Generate report
    generate_report
    
    echo -e "${OK} Package selection complete ($(wc -l < output/packages.txt) packages)"
    
    # Show summary
    whiptail --title "Package Summary" \
        --msgbox "Selected packages: $(wc -l < output/packages.txt)\n\nView output/report.md for details." 10 60
    
    return 0
}

# Step 4: Partition configuration
step_partition() {
    if [[ ! -f output/facts.txt ]]; then
        whiptail --title "Error" --msgbox "Hardware facts not found. Run detection first." 8 60
        return 1
    fi
    
    source output/facts.txt
    
    # Check if multiple disks
    if [[ "${DISK_CANDIDATES:-}" == *","* ]]; then
        local disk_array=()
        IFS=',' read -ra disks <<< "$DISK_CANDIDATES"
        local i=1
        for d in "${disks[@]}"; do
            local size=$(lsblk -d -b -n -o SIZE "/dev/$d" 2>/dev/null)
            [[ -n "$size" ]] && size="$((size / 1024 / 1024 / 1024))GB" || size="?"
            disk_array+=("$d" "/dev/$d ($size)" "OFF")
            ((i++))
        done
        
        local selected_disk
        selected_disk=$(whiptail --title "Multiple Disks Detected" \
            --radiolist "Select installation disk:" 15 70 5 \
            "${disk_array[@]}" \
            3>&1 1>&2 2>&3)
        
        if [[ -n "$selected_disk" ]]; then
            DISK_NAME="$selected_disk"
            sed -i "s|^DISK_NAME=.*|DISK_NAME=$DISK_NAME|" output/facts.txt
        fi
    fi
    
    # Ask about partition layout
    local layout_choice
    layout_choice=$(whiptail --title "Partition Layout" \
        --menu "Choose partition scheme:" 15 70 3 \
        "auto" "Automatic (EFI/swap/root)" \
        "custom" "Custom (interactive editor)" \
        "manual" "Manual (edit layout.txt)" \
        3>&1 1>&2 2>&3)
    
    case "$layout_choice" in
        custom)
            bash "$SCRIPT_DIR/main.sh" layout
            ;;
        manual)
            whiptail --title "Manual Layout" \
                --msgbox "Edit output/layout.txt manually.\n\nFormat:\n[mount] [filesystem] [size|rest]\n\nExample:\n[swap] linux-swap 8G\n/home ext4 100G\n/ btrfs rest" 15 60
            ;;
        *)
            # Auto layout
            source decide/partition.sh
            build_partitions > output/partition.txt
            ;;
    esac
    
    # Show partition plan
    if [[ -f output/partition.txt ]]; then
        whiptail --title "Partition Plan" --textbox output/partition.txt 20 70
    fi
    
    return 0
}

# Step 5: Validate packages
step_validate() {
    if [[ ! -f output/packages.txt ]]; then
        whiptail --title "Error" --msgbox "Package list not found. Run package configuration first." 8 60
        return 1
    fi
    
    echo -e "${INFO} Validating packages against official repos..."
    
    source lib/api.sh
    local total=0 ok=0 bad=0 missing_pkgs=""
    
    while read -r pkg; do
        ((total++))
        if pkg_exists "$pkg"; then
            ((ok++))
        else
            ((bad++))
            missing_pkgs+="- $pkg\n"
        fi
    done < output/packages.txt
    
    if [[ $bad -gt 0 ]]; then
        whiptail --title "Package Validation" \
            --msgbox "Validation: $ok/$total OK, $bad missing\n\nMissing packages (may be in AUR):\n$missing_pkgs" 20 70
        return 1
    else
        whiptail --title "Package Validation" \
            --msgbox "✓ All $total packages exist in official repos!" 8 60
        return 0
    fi
}

# Step 6: Generate install script
step_generate() {
    if [[ ! -f output/facts.txt || ! -f output/packages.txt ]]; then
        whiptail --title "Error" --msgbox "Required files missing. Complete detection and package selection first." 10 60
        return 1
    fi
    
    source output/facts.txt
    source decide/partition.sh
    source decide/install.sh
    
    build_install_plan > output/install.sh
    chmod +x output/install.sh
    
    echo -e "${OK} Install script generated: output/install.sh"
    
    # Show actions menu
    local action
    action=$(whiptail --title "Install Script Ready" \
        --menu "Script generated successfully!\n\nWhat would you like to do?" 16 70 3 \
        "view" "View the script" \
        "run" "Run the installation now" \
        "exit" "Return to main menu" \
        3>&1 1>&2 2>&3)
    
    case "$action" in
        view)
            whiptail --title "Install Script Preview" --textbox output/install.sh 30 90
            # After viewing, ask again
            step_generate
            ;;
        run)
            run_install_script
            ;;
        exit|"")
            return 0
            ;;
    esac
    
    return 0
}

# Run the install script
run_install_script() {
    if [[ ! -f output/install.sh ]]; then
        whiptail --title "Error" --msgbox "Install script not found. Generate it first." 8 60
        return 1
    fi
    
    # Final confirmation
    if ! whiptail --title "⚠️  FINAL CONFIRMATION" \
        --yesno "You are about to run the installation script!\n\n⚠️  WARNING:\n- This will partition and format disks\n- This will install Arch Linux\n- Only run inside a VM!\n\nThe script has safety checks and will refuse to run on:\n- Real hardware (non-VM)\n- Removable media (USB drives)\n\nDo you want to proceed?" 18 70; then
        return 0
    fi
    
    # Clear screen and run
    clear
    echo -e "${INFO} Starting installation..."
    echo -e "${INFO} Running: bash output/install.sh"
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    
    # Run the install script
    bash output/install.sh
    local exit_code=$?
    
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${OK} Installation completed successfully!"
        whiptail --title "✅ Installation Complete" --msgbox \
"Installation finished successfully!

Next steps:
1. The system is installed and configured
2. Reboot when ready: reboot
3. After reboot, run post-install scripts:
   - ~/arch_installer/postinstall/wine-setup.sh
   - ~/arch_installer/postinstall/steam-setup.sh
   - ~/arch_installer/postinstall/hyprland-keyboard.sh

Enjoy your new Arch Linux system!" 18 70
    else
        echo -e "${ERROR} Installation failed with exit code: $exit_code"
        whiptail --title "❌ Installation Failed" --msgbox \
"Installation failed with exit code: $exit_code

Check the output above for errors.

Common issues:
- Not running in a VM
- Disk is removable media
- Network connection issues
- Package download failures

Review the error messages and try again." 16 70
    fi
    
    read -rp "Press Enter to return to main menu..."
    return $exit_code
}

# View report
view_report() {
    if [[ ! -f output/report.md ]]; then
        whiptail --title "Error" --msgbox "Report not found. Run package configuration first." 8 60
        return 1
    fi
    
    whiptail --title "Installation Report" --textbox output/report.md 30 90
}

# Clean output
clean_output() {
    if whiptail --title "Clean Output" --yesno "Delete all generated files?\n\nThis will remove:\n- output/*.txt\n- output/*.md\n- output/install.sh" 12 60; then
        rm -f output/*.txt output/*.md output/install.sh
        echo -e "${OK} Output files cleaned"
        whiptail --title "Success" --msgbox "Output files have been cleaned." 8 50
    fi
}

# Generate report
generate_report() {
    cat > output/report.md << 'REPORT_EOF'
# Installation Report

## System Configuration

| Setting | Value |
|---|---|
REPORT_EOF
    
    # Add system configuration if set
    if grep -q '^HOST_NAME=' output/facts.txt; then
        echo "| Hostname | $(grep '^HOST_NAME=' output/facts.txt | cut -d= -f2) |" >> output/report.md
    fi
    if grep -q '^LOCALE=' output/facts.txt; then
        echo "| Locale | $(grep '^LOCALE=' output/facts.txt | cut -d= -f2) |" >> output/report.md
    fi
    if grep -q '^KEYMAP=' output/facts.txt; then
        echo "| Keyboard | $(grep '^KEYMAP=' output/facts.txt | cut -d= -f2) |" >> output/report.md
    fi
    if grep -q '^TIMEZONE=' output/facts.txt; then
        echo "| Timezone | $(grep '^TIMEZONE=' output/facts.txt | cut -d= -f2) |" >> output/report.md
    fi
    
    cat >> output/report.md << 'REPORT_EOF'

## Detected Hardware

| Fact | Value |
|---|---|
REPORT_EOF
    
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^(PROFILE|EXTRA_PACKAGES|HOST_NAME|LOCALE|KEYMAP|TIMEZONE)$ ]] && continue
        echo "| $key | $value |"
    done < output/facts.txt >> output/report.md
    
    cat >> output/report.md << 'REPORT_EOF'

## Packages and Reasons

| Package | Reason |
|---|---|
REPORT_EOF
    
    for p in "${!PACKAGES[@]}"; do
        echo "| $p | ${PACKAGES[$p]} |"
    done | sort >> output/report.md
}
