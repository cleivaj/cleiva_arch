#!/usr/bin/env bash

#Detect Disk

set -u

DISK=$(lsblk -d -n -o NAME,TYPE 2>/dev/null | awk '$2=="disk"{print $1; exit}')

if [[ -z "$DISK" ]]; then
    echo "DISK_NAME=none"
    echo "DISK_TYPE=unknown"
    echo "DISK_SIZE_GB=0"
    echo "DISK_ROTATIONAL=unknown"
    exit 0
fi

TRAN=$(lsblk -d -n -o TRAN "/dev/$DISK" 2>/dev/null)
ROTA=$(lsblk -d -n -o ROTA "/dev/$DISK" 2>/dev/null)
SIZE_B=$(lsblk -d -b -n -o SIZE "/dev/$DISK" 2>/dev/null)

case "$TRAN" in
nvme) TYPE=nvme ;;
usb) TYPE=usb ;;
sata | ata) TYPE=sata ;;
*) TYPE=unknown ;;
esac

echo "DISK_NAME=$DISK"
echo "DISK_TYPE=$TYPE"
echo "DISK_SIZE_GB=$((${SIZE_B:-0} / 1024 / 1024 / 1024))"
echo "DISK_ROTATIONAL=${ROTA:-unknown}"
