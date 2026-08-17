#!/usr/bin/env bash

#Packages

declare -A PACKAGES

add() {
    local pkg="$1" reason="$2"
    PACKAGES["$pkg"]="$reason"
}

build_packages() {
    #Base - always
    add base "Base system"
    add base-devel "Toolchain compilation (makepkg, AUR)"
    add linux "Kernel"
    add git "Version Controller"
    add nano "ide"
    add networkmanager "Network Manager"
    add sudo "root user"

    # CPU
    case "$CPU_VENDOR" in
    amd) add amd-ucode "AMD" ;;
    intel) add intel-ucode "intel" ;;
    esac

    # GPU
    if [[ "${VIRT:-none}" == "none" ]]; then
        case "$GPU_VENDOR" in
        amd)
            add mesa "GPU AMD => Drivers +  libGL"
            add vulkan-radeon "Vulkan"
            ;;
        nvidia) add nvidia-utils "GPU NVIDIA => drivers + libGL" ;;
        intel)
            add mesa "GPU Intel => drivers"
            add vulkan-intel "GPU Intel => Vulkan"
            ;;
        unknown) add mesa "GPU unknown => generic fallback" ;;
        esac
    else
        add mesa "VM => generic drivers"
    fi

    # Bluetooth
    [[ "$HAS_BLUETOOTH" == "yes" ]] && add bluez "Bluetooth" && add bluez-utils "Bluetooth utils"

    # Battery
    [[ "$HAS_BATTERY" == "yes" ]] && add brightnessctl "brightness" && add tlp "eco-mode"

    # Audio
    add pipewire "Audio"
    add pipewire-pulse "pulseAudio"
    add wireplumber "Audio sessions manager"

    # Profile Hyprland
    local hypr=(hyprland hyprpaper hyprlock hypridle waybar wofi kitty grim slurp
        wl-clipboard xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
        polkit-kde-agent ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji)
    local p
    for p in "${hypr[@]}"; do
        add "$p" "Profile Hyprland"
    done
}
