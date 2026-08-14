#!/usr/bin/env bash

#Detect GPU

set -u

if ! command -v lspci >/dev/null 2>&1; then
    echo "GPU_VENDOR=unknown"
    exit 0
fi

GPU_LINE=$(lspci 2>/dev/null | grep -Ei 'vga|3d controller|display controller' | head -1)

shopt -s nocasematch
case "$GPU_LINE" in
*nvidia*) echo "GPU_VENDOR=envidia" ;;
*amd* | *"advanced micro devices"*) echo "GPU_VENDOR=amd" ;;
*intel*) echo "GPU_VENDOR=intel" ;;
*) echo "GPU_VENDOR=unknown" ;;
esac
