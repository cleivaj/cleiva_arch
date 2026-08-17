#!/usr/bin/env bash
# Package selection menu module

menu_select_extra_packages() {
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
    
    echo "$extras"
}

add_extra_packages_to_tree() {
    local extras="$1"
    
    # Clean up quotes and spaces
    extras=$(echo "$extras" | tr -d '"' | tr '\n' ' ')
    
    [[ -z "$extras" ]] && return 0
    
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
}
