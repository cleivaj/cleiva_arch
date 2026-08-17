#!/usr/bin/env bash

#Packages

declare -A PACKAGES

add() {
    local pkg="$1" reason="$2"
    PACKAGES["$pkg"]="$reason"
}

build_packages() {
    local profile="${PROFILE:-hyprland}"
    
    #Base - always
    add base "Base system"
    add base-devel "Toolchain compilation (makepkg, AUR)"
    add linux "Kernel"
    add git "Version Controller"
    add nano "Text editor"
    add networkmanager "Network Manager"
    add sudo "Privilege elevation"

    # CPU microcode
    case "$CPU_VENDOR" in
    amd) add amd-ucode "CPU AMD => microcode updates" ;;
    intel) add intel-ucode "CPU Intel => microcode updates" ;;
    esac

    # GPU drivers
    if [[ "${VIRT:-none}" == "none" ]]; then
        case "$GPU_VENDOR" in
        amd)
            add mesa "GPU AMD => Drivers + libGL"
            add vulkan-radeon "GPU AMD => Vulkan support"
            ;;
        nvidia) 
            add nvidia-utils "GPU NVIDIA => drivers + libGL"
            add nvidia-settings "GPU NVIDIA => configuration tool"
            ;;
        intel)
            add mesa "GPU Intel => drivers + libGL"
            add vulkan-intel "GPU Intel => Vulkan support"
            ;;
        unknown) add mesa "GPU unknown => generic fallback" ;;
        esac
    else
        add mesa "VM => generic drivers"
    fi

    # Bluetooth
    if [[ "$HAS_BLUETOOTH" == "yes" ]]; then
        add bluez "Bluetooth stack"
        add bluez-utils "Bluetooth utilities"
    fi

    # Laptop-specific
    if [[ "$HAS_BATTERY" == "yes" ]]; then
        add brightnessctl "Laptop => brightness control"
        add tlp "Laptop => power management"
    fi

    # Audio
    add pipewire "Audio server"
    add pipewire-pulse "PulseAudio compatibility"
    add wireplumber "Audio session manager"

    # Desktop Profile
    case "$profile" in
        hyprland)
            # Core Hyprland packages
            local hypr=(hyprland hyprpaper hyprlock hypridle waybar wofi kitty grim slurp
                wl-clipboard xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
                polkit-kde-agent ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji)
            
            # File manager + dependencies (essential for desktop use)
            local file_mgr=(thunar thunar-volman tumbler gvfs gvfs-mtp)
            
            # Image viewer
            local viewer=(imv)
            
            local p
            for p in "${hypr[@]}"; do
                add "$p" "Profile Hyprland"
            done
            for p in "${file_mgr[@]}"; do
                add "$p" "Profile Hyprland => File manager"
            done
            for p in "${viewer[@]}"; do
                add "$p" "Profile Hyprland => Image viewer"
            done
            ;;
        minimal)
            # Minimal profile already has base packages
            ;;
        custom)
            # Custom packages added externally
            ;;
    esac
}
