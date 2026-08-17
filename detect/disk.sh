#!/usr/bin/env bash

#Detect Disk

set -u

# The device holding the Arch ISO (the USB stick you booted from) must never
# be chosen as install target. Find it via the boot mount, or the ARCH_* label.
BOOT_DISK=""
BOOT_SRC=$(findmnt -n -o SOURCE /run/archiso/bootmnt 2>/dev/null)
[[ -n "$BOOT_SRC" ]] && BOOT_DISK=$(lsblk -n -o PKNAME "$BOOT_SRC" 2>/dev/null)
if [[ -z "$BOOT_DISK" ]]; then
    for l in /dev/disk/by-label/ARCH*; do
        [[ -e "$l" ]] || continue
        BOOT_DISK=$(lsblk -n -o PKNAME "$(readlink -f "$l")" 2>/dev/null)
        [[ -n "$BOOT_DISK" ]] && break
    done
fi

# Candidates: real disks that are not the boot media, not USB, not removable
# (RM=1), and not zram/ram/loop.
CANDIDATES=$(lsblk -d -n -o NAME,TRAN,TYPE,RM 2>/dev/null | awk -v boot="$BOOT_DISK" '
    $3=="disk" && $2!="usb" && $4!="1" && $1 !~ /^(zram|ram|loop)/ && $1 != boot {print $1}
')

if [[ -z "$CANDIDATES" ]]; then
    echo "DISK_NAME=none"
    echo "DISK_CANDIDATES="
    echo "DISK_TYPE=unknown"
    echo "DISK_SIZE_GB=0"
    echo "DISK_ROTATIONAL=unknown"
    exit 0
fi

# Default target: first candidate. All of them are emitted so the
# orchestrator can ask the user when there is more than one.
DISK=$(echo "$CANDIDATES" | head -1)
echo "DISK_CANDIDATES=$(echo "$CANDIDATES" | paste -sd, -)"

TRAN=$(lsblk -d -n -o TRAN "/dev/$DISK" 2>/dev/null)
ROTA=$(lsblk -d -n -o ROTA "/dev/$DISK" 2>/dev/null)
SIZE_B=$(lsblk -d -b -n -o SIZE "/dev/$DISK" 2>/dev/null)

case "$TRAN" in
nvme) TYPE=nvme ;;
usb) TYPE=usb ;;
sata | ata) TYPE=sata ;;
mmc) TYPE=mmc ;;
*) TYPE=unknown ;;
esac

echo "DISK_NAME=$DISK"
echo "DISK_TYPE=$TYPE"
echo "DISK_SIZE_GB=$((${SIZE_B:-0} / 1024 / 1024 / 1024))"
echo "DISK_ROTATIONAL=${ROTA:-unknown}"
