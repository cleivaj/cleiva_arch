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

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source libraries and modules
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/steps.sh"

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
    ║        Hyprland Automated Installer v2.2              ║
    ║      Educational Edition - Interactive Setup          ║
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
    local menu_items=(
        "1" "🚀 Full Auto Install (Detect → Config → Install)"
        "2" "🔍 Detect Hardware Only"
        "3" "⚙️  Configure System (Timezone, Locale, Keyboard)"
        "4" "📦 Configure Packages & Profile"
        "5" "💾 Configure Disk Partitions"
        "6" "📊 View Detection Report"
        "7" "🧪 Validate Package List"
        "8" "📝 Generate Install Script"
    )
    
    # Add "Run Install" option if script exists
    if [[ -f output/install.sh ]]; then
        menu_items+=("9" "▶️  Run Installation Script")
        menu_items+=("10" "🧹 Clean Output Files")
        menu_items+=("0" "❌ Exit")
    else
        menu_items+=("9" "🧹 Clean Output Files")
        menu_items+=("0" "❌ Exit")
    fi
    
    choice=$(whiptail --title "Arch Installer - Main Menu" \
        --menu "Choose an option:" 24 75 14 \
        "${menu_items[@]}" \
        3>&1 1>&2 2>&3)
    
    echo "$choice"
}

# Full auto workflow
full_auto_install() {
    # Welcome
    if ! whiptail --title "Full Auto Install" \
        --yesno "This will run the complete installation workflow:\n\n1. Detect hardware\n2. Configure system (timezone, locale, keyboard)\n3. Configure packages\n4. Configure partitions\n5. Validate packages\n6. Generate install script\n\nContinue?" 17 70; then
        return 1
    fi
    
    # Step 1: Detect
    echo -e "\n${BOLD}Step 1/6: Hardware Detection${RESET}"
    step_detect || {
        whiptail --title "Error" --msgbox "Hardware detection failed!" 8 50
        return 1
    }
    sleep 1
    
    # Step 2: System Config
    echo -e "\n${BOLD}Step 2/6: System Configuration${RESET}"
    echo -e "${INFO} Starting system configuration..."
    
    if ! step_system_config; then
        whiptail --title "Error" --msgbox "System configuration cancelled or failed!" 8 50
        return 1
    fi
    
    echo -e "${OK} System configuration complete"
    sleep 1
    
    # Step 3: Packages
    echo -e "\n${BOLD}Step 3/6: Package Configuration${RESET}"
    step_packages || {
        whiptail --title "Error" --msgbox "Package configuration cancelled or failed!" 8 50
        return 1
    }
    sleep 1
    
    # Step 4: Partitions
    echo -e "\n${BOLD}Step 4/6: Partition Configuration${RESET}"
    step_partition || {
        whiptail --title "Error" --msgbox "Partition configuration failed!" 8 50
        return 1
    }
    sleep 1
    
    # Step 5: Validate
    echo -e "\n${BOLD}Step 5/6: Package Validation${RESET}"
    step_validate
    sleep 1
    
    # Step 6: Generate
    echo -e "\n${BOLD}Step 6/6: Generate Install Script${RESET}"
    step_generate || {
        whiptail --title "Error" --msgbox "Install script generation failed!" 8 50
        return 1
    }
    
    # Note: step_generate now handles view/run/exit internally
    return 0
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
        
        # Dynamic menu handling
        if [[ -f output/install.sh ]]; then
            # Menu with "Run Install" option
            case "$choice" in
                1) full_auto_install ;;
                2) step_detect && whiptail --title "Success" --msgbox "Hardware detected! See output/facts.txt" 8 50 ;;
                3) step_system_config ;;
                4) step_packages ;;
                5) step_partition ;;
                6) view_report ;;
                7) step_validate ;;
                8) step_generate ;;
                9) run_install_script ;;
                10) clean_output ;;
                0|"") 
                    echo -e "\n${INFO} Goodbye!\n"
                    exit 0
                    ;;
                *)
                    whiptail --title "Error" --msgbox "Invalid option" 8 40
                    ;;
            esac
        else
            # Menu without "Run Install" option
            case "$choice" in
                1) full_auto_install ;;
                2) step_detect && whiptail --title "Success" --msgbox "Hardware detected! See output/facts.txt" 8 50 ;;
                3) step_system_config ;;
                4) step_packages ;;
                5) step_partition ;;
                6) view_report ;;
                7) step_validate ;;
                8) step_generate ;;
                9) clean_output ;;
                0|"") 
                    echo -e "\n${INFO} Goodbye!\n"
                    exit 0
                    ;;
                *)
                    whiptail --title "Error" --msgbox "Invalid option" 8 40
                    ;;
            esac
        fi
    done
}

# Run main
main "$@"
