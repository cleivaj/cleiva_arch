#!/usr/bin/env bash
# Debug version of init.sh with verbose output

set -x  # Enable debug mode
set -euo pipefail

cd "$(dirname "$0")"

source lib/common.sh
source lib/steps.sh

echo "=== Starting Debug Mode ==="
echo "Working directory: $(pwd)"
echo ""

# Clean start
rm -f output/facts.txt output/packages.txt output/report.md output/install.sh

# Step 1: Detect
echo ">>> Running step_detect"
step_detect
echo "<<< step_detect completed"

# Step 2: System Config (this is where it might hang)
echo ">>> Running step_system_config"
step_system_config
echo "<<< step_system_config completed"

echo ""
echo "=== If you see this, it worked! ==="
cat output/facts.txt
