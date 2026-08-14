#!/usr/bin/env bash
#Detect virt

set -u

if command -v systemd-detect-virt >/dev/null 2>&1; then
    echo "VIRT=$(systemd-detect-virt)"
else
    echo "VIRT=unknown"
fi
