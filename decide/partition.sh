#!/usr/bin/env bash

#Partitions

# Suggests a partition layout from the facts (decision only, no disk changes)

build_partitions() {
    local disk="/dev/${DISK_NAME:-unknown}"
    local fs="ext4"
    [[ "${DISK_ROTATIONAL:-1}" == "0" ]] && fs="btrfs"

    local swap=0
    if ((RAM_GB <= 2)); then
        swap=$(($RAM_GB * 2))
    elif ((RAM_GB <= 8)); then
        swap=$(($RAM_GB))
    else
        swap=$(($RAM_GB / 2))
    fi

    DISK="$disk"
    FS_ROOT="$fs"
    SWAP_GB="$swap"
    PART_EFI="${disk}p1; PART_SWAP=${disk}p2; PART_ROOT=${disk}p3"

    echo "Disk: $disk (filesystem: $fs)"

    case "${FIRMWARE:-bios}" in
    uefi)
        echo " ${disk}p1 EFI system partition   512M    vfa         /efi"
        echo " ${disk}p2 swap                   ${swap}G    linux-swap      [swap]"
        echo " ${disk}p3 root                   rest    ${fs}       /"
        ;;
    bios)
        echo " ${disk}1 boot (MBR)      1M  bios_grub"
        echo " ${disk}2 swap            ${swap}G    linux-swap  [swap]"
        echo " ${disk}3 root             rest   ${fs}   /"
        ;;
    esac
}
