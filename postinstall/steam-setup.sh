#!/usr/bin/env bash
# Post-install Steam configuration
# Run this after first boot as your user (not root)

set -euo pipefail

echo "=== Steam Post-Install Configuration ==="
echo ""

# Check if Steam is installed
if ! command -v steam &>/dev/null; then
    echo "Error: Steam is not installed"
    exit 1
fi

echo "[1/3] Enabling multilib repository (32-bit support)..."
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo "Adding [multilib] to /etc/pacman.conf..."
    sudo bash -c 'cat >> /etc/pacman.conf << EOF

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF'
    sudo pacman -Sy
else
    echo "  ✓ [multilib] already enabled"
fi

echo ""
echo "[2/3] Installing recommended Steam dependencies..."
sudo pacman -S --needed --noconfirm \
    lib32-nvidia-utils \
    lib32-systemd \
    lib32-fontconfig \
    lib32-libxcb \
    lib32-libx11 \
    lib32-libxss \
    steam-native-runtime

echo ""
echo "[3/3] Setting up Proton compatibility..."
echo "Steam will download Proton automatically on first run."
echo ""
echo "For best gaming performance, enable in Steam:"
echo "  Settings → Compatibility → Enable Steam Play for all titles"
echo "  Select: Proton Experimental or latest Proton version"
echo ""

echo "=== Steam Setup Complete! ==="
echo ""
echo "Launch Steam with:"
echo "  steam"
echo ""
echo "Optional gaming enhancements:"
echo "  sudo pacman -S gamemode     # CPU governor for gaming"
echo "  sudo pacman -S mangohud     # Performance overlay"
echo ""
echo "For ProtonDB compatibility info:"
echo "  https://www.protondb.com/"
echo ""
