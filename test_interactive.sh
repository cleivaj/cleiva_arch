#!/usr/bin/env bash
# Quick test of the interactive installer components
# Run this to verify everything works before deploying to VM

set -uo pipefail

echo "=== Testing Interactive Installer Components ==="
echo ""

# Test 1: Check all required files exist
echo "[1/5] Checking file structure..."
required_files=(
    "init.sh"
    "main.sh"
    "lib/common.sh"
    "lib/api.sh"
    "decide/packages.sh"
    "decide/partition.sh"
    "decide/install.sh"
)

for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "  ✗ Missing: $file"
        exit 1
    fi
done
echo "  ✓ All required files present"

# Test 2: Check detection modules
echo "[2/5] Checking detection modules..."
detect_count=$(find detect -name "*.sh" -type f | wc -l)
if [[ $detect_count -lt 10 ]]; then
    echo "  ✗ Expected at least 10 detection modules, found $detect_count"
    exit 1
fi
echo "  ✓ Found $detect_count detection modules"

# Test 3: Run detection
echo "[3/5] Running hardware detection..."
./main.sh detect >/dev/null 2>&1
if [[ ! -f output/facts.txt ]]; then
    echo "  ✗ Detection failed, no facts.txt generated"
    exit 1
fi
fact_count=$(wc -l < output/facts.txt)
echo "  ✓ Detection successful ($fact_count facts detected)"

# Test 4: Test package decision
echo "[4/5] Testing package decision tree..."
source output/facts.txt
source decide/packages.sh
declare -A PACKAGES
build_packages
if [[ ${#PACKAGES[@]} -lt 10 ]]; then
    echo "  ✗ Too few packages decided: ${#PACKAGES[@]}"
    exit 1
fi
echo "  ✓ Package tree works (${#PACKAGES[@]} packages)"

# Test 5: Test partition generation
echo "[5/5] Testing partition generation..."
source decide/partition.sh
build_partitions >/dev/null 2>&1
if [[ -z "${DISK:-}" ]]; then
    echo "  ✗ Partition generation failed"
    exit 1
fi
echo "  ✓ Partition generation works"

echo ""
echo "=== All Tests Passed! ==="
echo ""
echo "Ready to use:"
echo "  ./init.sh           # Interactive mode"
echo "  ./main.sh all       # Command-line mode"
echo ""
