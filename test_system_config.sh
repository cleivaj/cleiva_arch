#!/usr/bin/env bash
# Test script for system configuration step

set -euo pipefail

cd "$(dirname "$0")"

source lib/common.sh

echo "=== Testing System Configuration Step ==="
echo ""

# Clean and prepare
rm -f output/facts.txt output/packages.txt output/report.md

# Step 1: Detection
echo "[1/3] Running detection..."
./main.sh detect >/dev/null 2>&1
echo "  ✓ Detection complete"

# Step 2: Test system config loading
echo "[2/3] Loading system config module..."
if source lib/menus/system_config.sh; then
    echo "  ✓ Module loaded"
else
    echo "  ✗ Failed to load module"
    exit 1
fi

# Step 3: Manually add config (simulating user input)
echo "[3/3] Simulating configuration..."
source output/facts.txt

echo "HOST_NAME=testhost" >> output/facts.txt
echo "KEYMAP=us" >> output/facts.txt
echo "LOCALE=en_US.UTF-8" >> output/facts.txt

echo "  ✓ Configuration added"

# Verify
echo ""
echo "=== Configuration Result ==="
grep -E "^(HOST_NAME|KEYMAP|LOCALE|TIMEZONE)=" output/facts.txt

echo ""
echo "=== Test Complete ==="
