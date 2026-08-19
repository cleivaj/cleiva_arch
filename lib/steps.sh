#!/usr/bin/env bash
# Installation steps module
#
# The non-interactive "core" actions (detect, build package list, validate,
# plan partitions, generate install script, report, select disk) live here so
# that both ./main.sh (CLI) and ./init.sh (interactive menu) share one
# implementation. The interactive whiptail wrappers are the step_* functions.

# Step 1: Detect hardware (non-interactive)
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

# Build output/packages.txt from the facts + PROFILE/EXTRA_PACKAGES.
# Requires output/facts.txt; sources it itself so it is self-contained.
build_package_list() {
    if [[ ! -f output/facts.txt ]]; then
        error "output/facts.txt not found — run detection first"
        return 1
    fi

    source output/facts.txt
    source decide/packages.sh
    build_packages

    if [[ -n "${EXTRA_PACKAGES:-}" ]]; then
        source lib/menus/packages.sh
        add_extra_packages_to_tree "$EXTRA_PACKAGES"
    fi

    for p in "${!PACKAGES[@]}"; do
        echo "$p"
    done | sort > output/packages.txt

    generate_report
    echo -e "${OK} Package selection complete ($(wc -l < output/packages.txt) packages)"
    return 0
}

# Validate output/packages.txt against the official repos (non-interactive).
# Prints results and sets MISSING_PKGS; returns 0 if all exist, 1 otherwise.
validate_packages() {
    if [[ ! -f output/packages.txt ]]; then
        error "output/packages.txt not found — run package selection first"
        return 1
    fi

    echo -e "${INFO} Validating packages against official repos..."

    source lib/api.sh
    MISSING_PKGS=""
    local total=0 ok=0 bad=0 pkg
    while read -r pkg; do
        ((total++))
        if pkg_exists "$pkg"; then
            ((ok++))
        else
            ((bad++))
            MISSING_PKGS+="- $pkg\n"
            warn "$pkg NOT FOUND"
        fi
    done < output/packages.txt

    if [[ $bad -gt 0 ]]; then
        error "$bad of $total packages missing (consider AUR)"
        return 1
    fi

    echo -e "${OK} All packages exist ($ok/$total)"
    return 0
}

# Choose the install disk when detection found several candidates.
# Prompts (whiptail, then plain read) only when stdin is a terminal; keeps the
# default otherwise. Idempotent: collapses DISK_CANDIDATES once resolved.
select_disk() {
    local candidates="${DISK_CANDIDATES:-$DISK_NAME}"
    if [[ "$candidates" != *","* ]]; then
        return 0
    fi

    local list=() d
    IFS=',' read -ra list <<< "$candidates"

    local chosen=""
    if [[ -t 0 ]] && command -v whiptail >/dev/null 2>&1; then
        local items=() size
        for d in "${list[@]}"; do
            size=$(lsblk -d -b -n -o SIZE "/dev/$d" 2>/dev/null)
            [[ -n "$size" ]] && size="$((size / 1024 / 1024 / 1024))GB" || size="?"
            items+=("$d" "/dev/$d ($size)" "OFF")
        done
        chosen=$(whiptail --title "Multiple Disks Detected" \
            --radiolist "Select installation disk:" 15 70 5 \
            "${items[@]}" \
            3>&1 1>&2 2>&3)
    elif [[ -t 0 ]]; then
        local i=1 size tran choice
        info "Multiple disks found — choose the install target:"
        for d in "${list[@]}"; do
            size=$(lsblk -d -b -n -o SIZE "/dev/$d" 2>/dev/null)
            [[ -n "$size" ]] && size="$((size / 1024 / 1024 / 1024))G" || size="?"
            tran=$(lsblk -d -n -o TRAN "/dev/$d" 2>/dev/null)
            printf '  %d) /dev/%s  (%s, %s)\n' "$i" "$d" "$size" "${tran:-unknown}"
            i=$((i + 1))
        done
        printf 'Choose [1-%d, Enter = 1]: ' "${#list[@]}"
        read -r choice
        [[ -z "$choice" ]] && choice=1
        if ! [[ "$choice" =~ ^[0-9]+$ ]] || ((choice < 1 || choice > ${#list[@]})); then
            warn "Invalid choice, using /dev/$DISK_NAME"
            return 0
        fi
        chosen="${list[$((choice - 1))]}"
    else
        warn "Multiple disks found ($candidates) but stdin is not a terminal — using /dev/$DISK_NAME"
        return 0
    fi

    if [[ -n "$chosen" ]]; then
        DISK_NAME="$chosen"
        DISK_CANDIDATES="$chosen"
        set_fact DISK_NAME "$DISK_NAME"
        set_fact DISK_CANDIDATES "$DISK_CANDIDATES"
        log "Install disk: /dev/$DISK_NAME"
    fi
    return 0
}

# Build output/partition.txt from the facts (non-interactive).
plan_partitions() {
    if [[ ! -f output/facts.txt ]]; then
        error "output/facts.txt not found — run detection first"
        return 1
    fi

    source output/facts.txt
    select_disk
    source decide/partition.sh
    build_partitions > output/partition.txt

    info "Partition plan:"
    cat output/partition.txt
    return 0
}

# Generate output/install.sh (non-interactive).
generate_install() {
    if [[ ! -f output/facts.txt || ! -f output/packages.txt ]]; then
        error "Required files missing. Run detection and package selection first."
        return 1
    fi

    source output/facts.txt
    select_disk
    source decide/partition.sh
    source decide/install.sh
    build_install_plan > output/install.sh
    chmod +x output/install.sh

    echo -e "${OK} Install script generated: output/install.sh"
    return 0
}

# Step 2: System configuration (interactive)
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
    set_fact HOST_NAME "$hostname"

    # Keyboard
    local kb_layout
    kb_layout=$(menu_select_keyboard)
    if [[ -z "$kb_layout" ]]; then
        kb_layout="us"
    fi
    set_fact KEYMAP "$kb_layout"

    # Locale
    local locale
    locale=$(menu_select_locale)
    if [[ -z "$locale" ]]; then
        locale="en_US.UTF-8"
    fi
    set_fact LOCALE "$locale"

    # Timezone
    local detected_tz="${TIMEZONE:-UTC}"
    local tz_choice
    tz_choice=$(menu_select_timezone "$detected_tz")
    if [[ -z "$tz_choice" ]]; then
        tz_choice="$detected_tz"
    fi
    set_fact TIMEZONE "$tz_choice"

    # User configuration
    local username user_password root_password

    username=$(menu_select_user)
    if [[ -n "$username" ]]; then
        set_fact USERNAME "$username"

        user_password=$(menu_select_user_password)
        if [[ -n "$user_password" ]]; then
            set_fact USER_PASSWORD "$user_password"
        fi
    fi

    root_password=$(menu_select_root_password)
    if [[ -n "$root_password" ]]; then
        set_fact ROOT_PASSWORD "$root_password"
    fi

    # Summary
    show_system_config_summary "$hostname" "$kb_layout" "$locale" "$tz_choice"

    return 0
}

# Step 3: Package selection (interactive wrapper around build_package_list)
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
    set_fact PROFILE "$profile"

    # Extra packages selection
    source lib/menus/packages.sh
    local extras
    extras=$(menu_select_extra_packages)
    extras=$(echo "$extras" | tr -d '"' | tr '\n' ' ')
    set_fact EXTRA_PACKAGES "$extras"

    # Build the package list (re-sources facts.txt, picking up PROFILE/EXTRA_PACKAGES)
    build_package_list || return 1

    # Show summary
    whiptail --title "Package Summary" \
        --msgbox "Selected packages: $(wc -l < output/packages.txt)\n\nView output/report.md for details." 10 60

    return 0
}

# Step 4: Partition configuration (interactive wrapper around plan_partitions)
step_partition() {
    if [[ ! -f output/facts.txt ]]; then
        whiptail --title "Error" --msgbox "Hardware facts not found. Run detection first." 8 60
        return 1
    fi

    source output/facts.txt
    select_disk

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
            plan_partitions
            ;;
    esac

    # Show partition plan
    if [[ -f output/partition.txt ]]; then
        whiptail --title "Partition Plan" --textbox output/partition.txt 20 70
    fi

    return 0
}

# Step 5: Validate packages (interactive wrapper around validate_packages)
step_validate() {
    validate_packages
    local rc=$?

    if [[ $rc -eq 0 ]]; then
        whiptail --title "Package Validation" \
            --msgbox "✓ All packages exist in official repos!" 8 60
    else
        whiptail --title "Package Validation" \
            --msgbox "Some packages are missing (may be in AUR):\n\n$MISSING_PKGS" 20 70
    fi

    return $rc
}

# Step 6: Generate install script (interactive wrapper around generate_install)
step_generate() {
    generate_install || return 1

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

# Run the install script (interactive)
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

# View report (interactive)
view_report() {
    if [[ ! -f output/report.md ]]; then
        whiptail --title "Error" --msgbox "Report not found. Run package configuration first." 8 60
        return 1
    fi

    whiptail --title "Installation Report" --textbox output/report.md 30 90
}

# Clean output (interactive)
clean_output() {
    if whiptail --title "Clean Output" --yesno "Delete all generated files?\n\nThis will remove:\n- output/*.txt\n- output/*.md\n- output/install.sh" 12 60; then
        rm -f output/*.txt output/*.md output/install.sh
        echo -e "${OK} Output files cleaned"
        whiptail --title "Success" --msgbox "Output files have been cleaned." 8 50
    fi
}

# Generate report (non-interactive)
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
