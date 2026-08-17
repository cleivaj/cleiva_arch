#!/usr/bin/env bash

#Detect GPU

set -u

if ! command -v lspci >/dev/null 2>&1; then
    echo "GPU_VENDOR=unknown"
    exit 0
fi

# All display lines, not just the first: hybrid laptops list the iGPU first.
GPU_LINES=$(lspci 2>/dev/null | grep -Ei 'vga|3d controller|display controller')

# Prefer the discrete GPU: NVIDIA or AMD beats an Intel iGPU when both exist.
shopt -s nocasematch
case "$GPU_LINES" in
*nvidia*) echo "GPU_VENDOR=nvidia" ;;
*amd* | *"advanced micro devices"*) echo "GPU_VENDOR=amd" ;;
*intel*) echo "GPU_VENDOR=intel" ;;
*) echo "GPU_VENDOR=unknown" ;;
esac
