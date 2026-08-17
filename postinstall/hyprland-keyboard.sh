#!/usr/bin/env bash
# Configure keyboard layout in Hyprland
# Run this after first boot as your user

set -euo pipefail

HYPR_CONF="$HOME/.config/hypr/hyprland.conf"

echo "=== Hyprland Keyboard Configuration ==="
echo ""

# Check if Hyprland config exists
if [[ ! -f "$HYPR_CONF" ]]; then
    echo "Error: Hyprland config not found at $HYPR_CONF"
    echo "Please start Hyprland first to generate default config."
    exit 1
fi

# Get keyboard layout from vconsole
KEYMAP=$(grep '^KEYMAP=' /etc/vconsole.conf 2>/dev/null | cut -d= -f2)
KEYMAP=${KEYMAP:-us}

echo "Detected keyboard layout: $KEYMAP"
echo ""

# Check if input section exists
if grep -q "input {" "$HYPR_CONF"; then
    echo "Input section already exists in config."
    
    # Check if kb_layout is set
    if grep -q "kb_layout" "$HYPR_CONF"; then
        current_layout=$(grep "kb_layout" "$HYPR_CONF" | head -1 | sed 's/.*= *\(.*\)/\1/')
        echo "Current layout: $current_layout"
        
        read -rp "Update to $KEYMAP? (y/n): " update
        if [[ "$update" =~ ^[Yy]$ ]]; then
            sed -i "s/kb_layout *=.*/kb_layout = $KEYMAP/" "$HYPR_CONF"
            echo "✓ Keyboard layout updated to: $KEYMAP"
        fi
    else
        # Add kb_layout to existing input section
        sed -i "/input {/a\\    kb_layout = $KEYMAP" "$HYPR_CONF"
        echo "✓ Keyboard layout added: $KEYMAP"
    fi
else
    # Create new input section
    cat >> "$HYPR_CONF" << EOF

# Keyboard configuration (added by post-install script)
input {
    kb_layout = $KEYMAP
    kb_variant =
    kb_model =
    kb_options =
    kb_rules =
    
    follow_mouse = 1
    
    touchpad {
        natural_scroll = false
    }
    
    sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
}
EOF
    echo "✓ Input section created with layout: $KEYMAP"
fi

echo ""
echo "=== Configuration Complete! ==="
echo ""
echo "Reload Hyprland to apply changes:"
echo "  SUPER + SHIFT + R  (or restart Hyprland)"
echo ""
echo "Additional keyboard options you can set manually in $HYPR_CONF:"
echo "  kb_variant = nodeadkeys   # For layouts with dead keys"
echo "  kb_options = grp:alt_shift_toggle  # To switch between layouts"
echo ""
echo "For multiple layouts (e.g., US + Spanish):"
echo "  kb_layout = us,es"
echo "  kb_options = grp:alt_shift_toggle"
echo ""
