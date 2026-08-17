#!/usr/bin/env bash
# KooL-inspired Interactive Arch Installer with Hyprland
# Author: cleiva
# One command to rule them all: ./init.sh

set -uo pipefail

# Colors and formatting
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' BOLD='' RESET=''
fi

OK="${GREEN}[✓]${RESET}"
ERROR="${RED}[✗]${RESET}"
INFO="${BLUE}[ℹ]${RESET}"
WARN="${YELLOW}[⚠]${RESET}"
ACTION="${CYAN}[→]${RESET}"

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Banner
show_banner() {
    clear
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════╗
    ║                                                       ║
    ║     ▄▄▄       ██▀███   ▄████▄   ██░ ██                ║
    ║    ▒████▄    ▓██ ▒ ██▒▒██▀ ▀█  ▓██░ ██▒               ║
    ║    ▒██  ▀█▄  ▓██ ░▄█ ▒▒▓█    ▄ ▒██▀▀██░               ║
    ║    ░██▄▄▄▄██ ▒██▀▀█▄  ▒▓▓▄ ▄██▒░▓█ ░██                ║
    ║     ▓█   ▓██▒░██▓ ▒██▒▒ ▓███▀ ░░▓█▒░██▓               ║
    ║     ▒▒   ▓▒█░░ ▒▓ ░▒▓░░ ░▒ ▒  ░ ▒ ░░▒░▒               ║
    ║      ▒   ▒▒ ░  ░▒ ░ ▒░  ░  ▒    ▒ ░▒░ ░               ║
    ║      ░   ▒     ░░   ░ ░         ░  ░░ ░               ║
    ║          ░  ░   ░     ░ ░       ░  ░  ░               ║
    ║                       ░                               ║
    ║           Hyprland Automated Installer               ║
    ║                Educational Edition                    ║
    ╚═══════════════════════════════════════════════════════╝
EOF
    printf "\n"
}

# Check if running in a VM (for safety in install phase)
check_vm() {
    local virt_type
    virt_type=$(systemd-detect-virt 2>/dev/null || echo "unknown")
    if [[ "$virt_type" == "none" ]]; then
        return 1  # Not in VM
    fi
    return 0  # In VM
}

# Install whiptail if needed
ensure_whiptail() {
    if ! command -v whiptail &>/dev/null; then
        echo -e "${INFO} Installing whiptail for interactive menus..."
        sudo pacman -S --noconfirm libnewt 2>/dev/null || {
            echo -e "${ERROR} Failed to install whiptail"
            return 1
        }
    fi
}

# Main menu
main_menu() {
    local choice
    choice=$(whiptail --title "Arch Installer - Main Menu" \
        --menu "Choose an option:" 20 70 10 \
        "1" "🚀 Full Auto Install (Detect → Decide → Partition → Install)" \
        "2" "🔍 Detect Hardware Only" \
        "3" "📦 Configure Packages & Profile" \
        "4" "💾 Configure Disk Partitions" \
        "5" "📊 View Detection Report" \
        "6" "🧪 Validate Package List" \
        "7" "📝 Generate Install Script" \
        "8" "🧹 Clean Output Files" \
        "9" "❌ Exit" \
        3>&1 1>&2 2>&3)
    
    echo "$choice"
}

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

# Step 2: Package selection menu
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
    local extras
    extras=$(whiptail --title "Additional Software & Tools" \
        --checklist "Select packages to install (SPACE to select, TAB to navigate):" 24 85 16 \
        "thunar" "Thunar file manager (recommended for Hyprland)" OFF \
        "nodejs" "Node.js JavaScript runtime" OFF \
        "npm" "Node package manager" OFF \
        "mariadb" "MariaDB database server" OFF \
        "postgresql" "PostgreSQL database" OFF \
        "docker" "Docker containerization" OFF \
        "docker-compose" "Docker Compose" OFF \
        "code" "Visual Studio Code (AUR)" OFF \
        "firefox" "Firefox web browser" OFF \
        "chromium" "Chromium web browser" OFF \
        "wine" "Wine (run Windows apps) + dependencies" OFF \
        "steam" "Steam gaming platform" OFF \
        "vlc" "VLC media player + codecs" OFF \
        "gimp" "GIMP image editor" OFF \
        "vim" "Vim text editor (enhanced)" OFF \
        "neovim" "Neovim text editor" OFF \
        "tmux" "Terminal multiplexer" OFF \
        3>&1 1>&2 2>&3)
    
    # Save extra packages
    if [[ -n "$extras" ]]; then
        # Clean up quotes and spaces
        extras=$(echo "$extras" | tr -d '"' | tr '\n' ' ')
        echo "EXTRA_PACKAGES=\"$extras\"" >> output/facts.txt
    fi
    
    # Run package decision tree
    source decide/packages.sh
    build_packages
    
    # Add extra packages
    if [[ -n "$extras" ]]; then
        for pkg in $extras; do
            case "$pkg" in
                thunar) 
                    add thunar "User: Thunar file manager"
                    add thunar-volman "User: Thunar volume manager"
                    add tumbler "User: Thunar thumbnails"
                    add thunar-archive-plugin "User: Thunar archive support"
                    add file-roller "User: Archive manager for Thunar"
                    add gvfs "User: Virtual filesystem (trash, network, etc.)"
                    add gvfs-mtp "User: MTP device support (Android phones)"
                    ;;
                nodejs) add nodejs "User: Node.js runtime" ;;
                npm) add npm "User: NPM package manager" ;;
                mariadb) add mariadb "User: MariaDB database" ;;
                postgresql) add postgresql "User: PostgreSQL database" ;;
                docker) 
                    add docker "User: Docker containers"
                    add docker-buildx "User: Docker buildx plugin"
                    ;;
                docker-compose) add docker-compose "User: Docker Compose" ;;
                code) add code "User: VS Code editor" ;;
                firefox) add firefox "User: Firefox browser" ;;
                chromium) add chromium "User: Chromium browser" ;;
                wine)
                    add wine "User: Wine compatibility layer"
                    add wine-mono "User: Wine .NET support"
                    add wine-gecko "User: Wine browser support"
                    add winetricks "User: Wine configuration tool"
                    add lib32-mesa "User: 32-bit graphics for Wine"
                    add lib32-vulkan-icd-loader "User: 32-bit Vulkan for Wine"
                    # Add lib32 GPU drivers based on detected GPU
                    if [[ "${VIRT:-none}" == "none" ]]; then
                        case "${GPU_VENDOR:-unknown}" in
                            amd) add lib32-vulkan-radeon "User: 32-bit AMD Vulkan for Wine" ;;
                            nvidia) add lib32-nvidia-utils "User: 32-bit NVIDIA libs for Wine" ;;
                            intel) add lib32-vulkan-intel "User: 32-bit Intel Vulkan for Wine" ;;
                        esac
                    fi
                    ;;
                steam)
                    add steam "User: Steam gaming platform"
                    add lib32-mesa "User: 32-bit graphics for Steam"
                    add lib32-vulkan-icd-loader "User: 32-bit Vulkan for Steam"
                    # Add lib32 GPU drivers for Steam
                    if [[ "${VIRT:-none}" == "none" ]]; then
                        case "${GPU_VENDOR:-unknown}" in
                            amd) add lib32-vulkan-radeon "User: 32-bit AMD Vulkan for Steam" ;;
                            nvidia) add lib32-nvidia-utils "User: 32-bit NVIDIA libs for Steam" ;;
                            intel) add lib32-vulkan-intel "User: 32-bit Intel Vulkan for Steam" ;;
                        esac
                    fi
                    ;;
                vlc) 
                    add vlc "User: VLC media player"
                    add ffmpeg "User: Multimedia codecs"
                    add x264 "User: H.264 codec"
                    add x265 "User: H.265/HEVC codec"
                    add libva-mesa-driver "User: Hardware video acceleration"
                    add libvdpau-va-gl "User: VDPAU acceleration"
                    ;;
                gimp) 
                    add gimp "User: GIMP image editor"
                    add gimp-help-en "User: GIMP documentation"
                    ;;
                vim) add vim "User: Vim editor" ;;
                neovim) add neovim "User: Neovim editor" ;;
                tmux) add tmux "User: Terminal multiplexer" ;;
            esac
        done
    fi
    
    # Write packages
    for p in "${!PACKAGES[@]}"; do
        echo "$p"
    done | sort > output/packages.txt
    
    # Generate report
    cat > output/report.md << 'REPORT_EOF'
# Installation Report

## Detected Facts

| Fact | Value |
|---|---|
REPORT_EOF
    
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^(PROFILE|EXTRA_PACKAGES)$ ]] && continue
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
    
    echo -e "${OK} Package selection complete ($(wc -l < output/packages.txt) packages)"
    
    # Show summary
    whiptail --title "Package Summary" \
        --msgbox "Selected packages: $(wc -l < output/packages.txt)\n\nView output/report.md for details." 10 60
    
    return 0
}

# Step 3: Partition configuration
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

# Step 4: Validate packages
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

# Step 5: Generate install script
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
    
    whiptail --title "Install Script Ready" \
        --yesno "Install script generated successfully!\n\nFile: output/install.sh\n\nWould you like to view it now?" 12 60
    
    if [[ $? -eq 0 ]]; then
        whiptail --title "Install Script Preview" --textbox output/install.sh 30 90
    fi
    
    return 0
}

# Full auto workflow
full_auto_install() {
    # Welcome
    if ! whiptail --title "Full Auto Install" \
        --yesno "This will run the complete installation workflow:\n\n1. Detect hardware\n2. Configure packages\n3. Configure partitions\n4. Validate packages\n5. Generate install script\n\nContinue?" 15 70; then
        return 1
    fi
    
    # Step 1: Detect
    echo -e "\n${BOLD}Step 1/5: Hardware Detection${RESET}"
    step_detect || {
        whiptail --title "Error" --msgbox "Hardware detection failed!" 8 50
        return 1
    }
    sleep 1
    
    # Step 2: Packages
    echo -e "\n${BOLD}Step 2/5: Package Configuration${RESET}"
    step_packages || {
        whiptail --title "Error" --msgbox "Package configuration cancelled or failed!" 8 50
        return 1
    }
    sleep 1
    
    # Step 3: Partitions
    echo -e "\n${BOLD}Step 3/5: Partition Configuration${RESET}"
    step_partition || {
        whiptail --title "Error" --msgbox "Partition configuration failed!" 8 50
        return 1
    }
    sleep 1
    
    # Step 4: Validate
    echo -e "\n${BOLD}Step 4/5: Package Validation${RESET}"
    step_validate
    sleep 1
    
    # Step 5: Generate
    echo -e "\n${BOLD}Step 5/5: Generate Install Script${RESET}"
    step_generate || {
        whiptail --title "Error" --msgbox "Install script generation failed!" 8 50
        return 1
    }
    
    # Final instructions
    whiptail --title "Installation Ready!" --msgbox \
"✓ All preparation complete!

Your install script is ready at:
  output/install.sh

Next steps:
1. Review the script: less output/install.sh
2. Copy to VM/target system
3. Run: bash output/install.sh

IMPORTANT: The script ONLY runs inside a VM for safety!

Post-Installation:
- Wine setup: ~/postinstall/wine-setup.sh
- Steam setup: ~/postinstall/steam-setup.sh
- Thunar is included as file manager
- Press SUPER+E to open file manager in Hyprland" 22 75
    
    return 0
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

# Main loop
main() {
    show_banner
    
    # Ensure we're in the right directory
    cd "$SCRIPT_DIR" || {
        echo -e "${ERROR} Failed to change to script directory"
        exit 1
    }
    
    # Check for whiptail
    ensure_whiptail || {
        echo -e "${ERROR} This script requires whiptail"
        exit 1
    }
    
    while true; do
        choice=$(main_menu)
        
        case "$choice" in
            1) full_auto_install ;;
            2) step_detect && whiptail --title "Success" --msgbox "Hardware detected! See output/facts.txt" 8 50 ;;
            3) step_packages ;;
            4) step_partition ;;
            5) view_report ;;
            6) step_validate ;;
            7) step_generate ;;
            8) clean_output ;;
            9|"") 
                echo -e "\n${INFO} Goodbye!\n"
                exit 0
                ;;
            *)
                whiptail --title "Error" --msgbox "Invalid option" 8 40
                ;;
        esac
    done
}

# Run main
main "$@"
