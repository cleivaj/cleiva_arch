#!/usr/bin/env bash
#Detect Battery

set -u

if cat /sys/class/power_supply/*/type 2>/dev/null | grep -q '^Battery$'; then
    echo "HAS_BATTERY=yes"
else
    echo "HAS_BATTERY=no"
fi
