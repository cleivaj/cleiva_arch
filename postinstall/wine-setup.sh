#!/usr/bin/env bash
# Post-install Wine configuration
# Run this after first boot as your user (not root)

set -euo pipefail

echo "=== Wine Post-Install Configuration ==="
echo ""

# Check if Wine is installed
if ! command -v wine &>/dev/null; then
    echo "Error: Wine is not installed"
    exit 1
fi

echo "[1/4] Enabling multilib repository (32-bit support)..."
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
echo "[2/4] Installing additional 32-bit libraries..."
sudo pacman -S --needed --noconfirm \
    lib32-gnutls \
    lib32-libpulse \
    lib32-alsa-plugins \
    lib32-pipewire \
    lib32-libxcomposite \
    lib32-libxinerama

echo ""
echo "[3/4] Creating Wine prefix..."
if [[ ! -d "$HOME/.wine" ]]; then
    echo "Initializing Wine prefix (this may take a minute)..."
    WINEARCH=win64 wineboot --init
    echo "  ✓ Wine prefix created at ~/.wine"
else
    echo "  ✓ Wine prefix already exists"
fi

echo ""
echo "[4/4] Setting up winetricks..."
if command -v winetricks &>/dev/null; then
    echo "Winetricks is installed. You can use it to install:"
    echo "  - winetricks dotnet48    # .NET Framework"
    echo "  - winetricks vcrun2019   # Visual C++ Runtime"
    echo "  - winetricks dxvk        # Vulkan-based D3D11/10/9"
    echo "  - winetricks d3dx9       # DirectX 9"
else
    echo "Warning: winetricks not found"
fi

echo ""
echo "=== Wine Setup Complete! ==="
echo ""
echo "Test Wine with:"
echo "  wine notepad"
echo ""
echo "For gaming, consider installing:"
echo "  winetricks dxvk      # For better DirectX performance"
echo "  winetricks vcrun2019 # For many Windows apps"
echo ""
echo "Wine configuration GUI:"
echo "  winecfg"
echo ""
