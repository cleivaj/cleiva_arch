#!/usr/bin/env bash
# Detect firmaware: UEFI vs BIOS (legacy).

set -u

if [[ -d /sys/firmware/efi ]]; then
    echo "FIRMWARE=uefi"
else
    echo "FIRMWARE=bios"
fi
