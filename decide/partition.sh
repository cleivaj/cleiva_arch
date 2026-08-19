#!/usr/bin/env bash

#Partitions

# Suggests a partition layout from the facts (decision only, no disk changes).
# The boot partition is automatic (EFI for UEFI, bios_grub for BIOS). The
# rest comes from a custom layout (output/layout.txt or $LAYOUT) or, by
# default, from the automatic rules: swap from RAM, root on the rest.

partition_suffix() {
    # NVMe/mmcblk/loop devices name partitions with a "p" (nvme0n1p1);
    # SATA/VirtIO devices don't (sda1, vda1).
    if [[ "${DISK_NAME:-}" =~ [0-9]$ ]]; then
        echo "p"
    fi
}

# "512M"/"8G" → "+512M"/"+8G" for sgdisk; "rest" → "0"
sgdisk_size() {
    [[ "$1" == "rest" ]] && echo "0" || echo "+$1"
}

# filesystem → mkfs command ("" = nothing to format, e.g. bios_grub)
mkfs_cmd_for() {
    case "$1" in
    vfat) echo "mkfs.fat -F32" ;;
    linux-swap) echo "mkswap" ;;
    btrfs) echo "mkfs.btrfs -f" ;;
    ext4) echo "mkfs.ext4 -F" ;;
    *) echo "" ;;
    esac
}

# mount point → sgdisk type code
type_code_for() {
    case "$1" in
    /efi) echo "ef00" ;;
    "[swap]") echo "8200" ;;
    "[bios_grub]") echo "ef02" ;;
    *) echo "8300" ;;
    esac
}

# default filesystem for a data partition: SSD → btrfs, HDD → ext4
default_fs() {
    [[ "${DISK_ROTATIONAL:-1}" == "0" ]] && echo "btrfs" || echo "ext4"
}

# swap size from the RAM rule: ≤2G → 2x, ≤8G → 1x, >8G → half (min 2G)
auto_swap_size() {
    local ram=${1:-0} swap=0
    if ((ram <= 2)); then
        swap=$((ram * 2))
    elif ((ram <= 8)); then
        swap=$((ram))
    else
        swap=$((ram / 2))
    fi
    ((swap < 1)) && swap=2
    echo "${swap}G"
}

build_partitions() {
    local disk="/dev/${DISK_NAME:-unknown}"
    local suffix; suffix=$(partition_suffix)
    local fs; fs=$(default_fs)
    local ram="${RAM_GB:-0}"

    LAYOUT_ENTRIES=() # "mount|fs|size", one per partition

    # 1. Boot partition — always first, never user-editable
    if [[ "${FIRMWARE:-bios}" == "uefi" ]]; then
        LAYOUT_ENTRIES+=("/efi|vfat|512M")
    else
        LAYOUT_ENTRIES+=("[bios_grub]|bios_grub|1M")
    fi

    # Custom layout source (comments and blank lines ignored)
    local layout_src=""
    if [[ -f output/layout.txt ]]; then
        layout_src=$(grep -vE '^[[:space:]]*(#|$)' output/layout.txt)
    elif [[ -n "${LAYOUT:-}" ]]; then
        layout_src=$(printf '%s\n' "$LAYOUT" | grep -vE '^[[:space:]]*(#|$)')
    fi

    if [[ -n "$layout_src" ]]; then
        # Custom layout: boot + whatever the user defined (+ root if missing)
        local mp="" f="" size="" has_root=0
        while read -r mp f size; do
            [[ -z "$mp" ]] && continue
            case "$mp" in
            "[swap]")
                if [[ "$size" == "auto" ]]; then
                    size=$(auto_swap_size "$ram")
                fi
                LAYOUT_ENTRIES+=("[swap]|${f:-linux-swap}|$size")
                ;;
            "/")
                has_root=1
                LAYOUT_ENTRIES+=("/|${f:-$fs}|$size")
                ;;
            "/efi" | "[bios_grub]")
                warn "Ignoring $mp: the boot partition is automatic"
                ;;
            /*)
                LAYOUT_ENTRIES+=("$mp|${f:-$fs}|$size")
                ;;
            *)
                warn "Ignoring invalid layout line: $mp $f $size"
                ;;
            esac
        done <<<"$layout_src"
        if ((has_root == 0)); then
            LAYOUT_ENTRIES+=("/|$fs|rest")
        fi
    else
        # Automatic: swap from RAM, root on the rest
        LAYOUT_ENTRIES+=("[swap]|linux-swap|$(auto_swap_size "$ram")")
        LAYOUT_ENTRIES+=("/|$fs|rest")
    fi

    # Sanity: "rest" must be unique and last
    local n_rest=0 last=0 i=0 entry=""
    for entry in "${LAYOUT_ENTRIES[@]}"; do
        i=$((i + 1))
        case "$entry" in
        *"|rest") n_rest=$((n_rest + 1)); last=$i ;;
        esac
    done
    if ((n_rest > 1)); then
        warn "Layout has $n_rest partitions sized 'rest' — only one is valid"
    elif ((n_rest == 1 && last != ${#LAYOUT_ENTRIES[@]})); then
        warn "Layout: the 'rest' partition is not the last one"
    fi

    # Facts for the consumers (install.sh, cmd_partition)
    DISK="$disk"
    FS_ROOT="$fs"
    SWAP_GB=0
    PART_EFI=""; PART_SWAP=""; PART_ROOT=""
    local k=1 entry2="" mp2="" f2="" size2=""
    for entry2 in "${LAYOUT_ENTRIES[@]}"; do
        IFS='|' read -r mp2 f2 size2 <<<"$entry2"
        local part="/dev/${DISK_NAME}${suffix}${k}"
        case "$mp2" in
        /efi) PART_EFI="$part" ;;
        "[swap]")
            PART_SWAP="$part"
            [[ "$size2" =~ ^[0-9]+G$ ]] && SWAP_GB="${size2%G}"
            ;;
        /) PART_ROOT="$part"; FS_ROOT="$f2" ;;
        esac
        k=$((k + 1))
    done

    # Print the plan
    echo "Disk: $disk"
    local j=1
    for entry in "${LAYOUT_ENTRIES[@]}"; do
        IFS='|' read -r mp f size <<<"$entry"
        printf ' %s  %-8s  %-10s  %s\n' "/dev/${DISK_NAME}${suffix}${j}" "$size" "$f" "$mp"
        j=$((j + 1))
    done
}
