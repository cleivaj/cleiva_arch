#!/usr/bin/env bash

#Partitions

# Suggests a partition layout from the facts (decision only, no disk changes)

partition_suffix() {
    # NVMe/mmcblk/loop devices name partitions with a "p" (nvme0n1p1);
    # SATA/VirtIO devices don't (sda1, vda1).
    if [[ "${DISK_NAME:-}" =~ [0-9]$ ]]; then
        echo "p"
    fi
}

build_partitions() {
    local disk="/dev/${DISK_NAME:-unknown}"
    local fs="ext4"
    [[ "${DISK_ROTATIONAL:-1}" == "0" ]] && fs="btrfs"

    local suffix
    suffix=$(partition_suffix)

    local ram=${RAM_GB:-0}
    local swap=0
    if ((ram <= 2)); then
        swap=$((ram * 2))
    elif ((ram <= 8)); then
        swap=$((ram))
    else
        swap=$((ram / 2))
    fi
    ((swap < 1)) && swap=2 # unknown RAM (RAM_GB=0) → safe default

    DISK="$disk"
    FS_ROOT="$fs"
    SWAP_GB="$swap"
    PART_EFI="${disk}${suffix}1"
    PART_SWAP="${disk}${suffix}2"
    PART_ROOT="${disk}${suffix}3"

    echo "Disk: $disk (filesystem: $fs)"

    case "${FIRMWARE:-bios}" in
    uefi)
        echo " ${PART_EFI}   EFI system partition   512M    vfat        /efi"
        echo " ${PART_SWAP}  swap                    ${swap}G   linux-swap  [swap]"
        echo " ${PART_ROOT}  root                    rest    ${fs}       /"
        ;;
    bios)
        echo " ${disk}${suffix}1  BIOS boot (GPT)         1M     bios_grub"
        echo " ${disk}${suffix}2  swap                     ${swap}G   linux-swap  [swap]"
        echo " ${disk}${suffix}3  root                     rest    ${fs}       /"
        ;;
    esac
}
