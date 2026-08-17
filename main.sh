#!/usr/bin/env bash

#Orchestrator

set -uo pipefail
source lib/common.sh
source lib/api.sh

usage() {
    echo "Usage: $0 <detect|decide|search|check|all|partition|install|layout|clean>"
}

if [[ $# -lt 1 ]]; then
    usage
    exit 1
fi

cmd_detect() {
    mkdir -p output
    for f in detect/*.sh; do
        bash "$f" 2>/dev/null || true
    done | sort >output/facts.txt
    info "Detected facts:"
    cat output/facts.txt
}

cmd_decide() {
    source output/facts.txt
    source decide/packages.sh
    build_packages
    for p in "${!PACKAGES[@]}"; do
        echo "$p"
    done | sort >output/packages.txt
    info "Packages decided: $(wc -l <output/packages.txt)"
    cat output/packages.txt

    cat >output/report.md <<'EOF'
# Installation Report
 
## Detected facts
 
| Fact | Value |
|---|---|
EOF
    while IFS='=' read -r key value; do
        echo "| $key | $value |"
    done <output/facts.txt >>output/report.md

    cat >>output/report.md <<'EOF'
 
## Packages and reasons
 
| Package | Reason |
|---|---|
EOF
    for p in "${!PACKAGES[@]}"; do
        echo "| $p | ${PACKAGES[$p]} |"
    done | sort >>output/report.md

}

cmd_search() {
    local q="$1" json
    json=$(search_pkg "$q") || {
        error "Search failed"
        return 1
    }
    echo "$json" | grep -oE '"pkgname": "[^"]*"|"pkgver": "[^"]*"|"repo": "[^"]*"'
}

cmd_check() {
    local total=0 ok=0 bad=0 pkg
    while read -r pkg; do
        total=$((total + 1))
        if pkg_exists "$pkg"; then
            ok=$((ok + 1))
        else
            bad=$((bad + 1))
            warn "$pkg NOT FOUND"
        fi
    done <output/packages.txt

    if [[ $bad -gt 0 ]]; then
        error "$bad of $total packages missing (consider AUR)"
        return 1
    fi

    log "All packages exist ($ok/$total)"
}

cmd_clean() {
    rm -f output/*.txt output/*.md output/install.sh
    info "Output cleaned"
}

# Ask which disk to install to when detection found several candidates.
# Requires output/facts.txt to be sourced already. Non-interactive (no
# TTY): keeps the default (first candidate) with a warning.
select_disk() {
    local candidates="${DISK_CANDIDATES:-$DISK_NAME}"
    if [[ "$candidates" != *","* ]]; then
        return 0
    fi
    if [[ ! -t 0 ]]; then
        warn "Multiple disks found ($candidates) but stdin is not a terminal — using /dev/$DISK_NAME"
        return 0
    fi

    local i=1 d size tran
    info "Multiple disks found — choose the install target:"
    IFS=',' read -ra list <<<"$candidates"
    for d in "${list[@]}"; do
        size=$(lsblk -d -b -n -o SIZE "/dev/$d" 2>/dev/null)
        if [[ -n "$size" ]]; then
            size="$((size / 1024 / 1024 / 1024))G"
        else
            size="?"
        fi
        tran=$(lsblk -d -n -o TRAN "/dev/$d" 2>/dev/null)
        printf '  %d) /dev/%s  (%s, %s)\n' "$i" "$d" "$size" "${tran:-unknown}"
        i=$((i + 1))
    done
    printf 'Choose [1-%d, Enter = 1]: ' "${#list[@]}"
    read -r choice
    [[ -z "$choice" ]] && choice=1
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || ((choice < 1 || choice > ${#list[@]})); then
        warn "Invalid choice, using /dev/$DISK_NAME"
        return 0
    fi

    DISK_NAME="${list[$((choice - 1))]}"
    sed -i "s|^DISK_NAME=.*|DISK_NAME=$DISK_NAME|" output/facts.txt
    log "Install disk: /dev/$DISK_NAME"
}

cmd_all() {
    cmd_detect
    cmd_decide
    cmd_check
}

cmd_partition() {
    source output/facts.txt
    select_disk
    source decide/partition.sh
    build_partitions >output/partition.txt
    info "Partition plan:"
    cat output/partition.txt
}

cmd_install() {
    source output/facts.txt
    select_disk
    source decide/partition.sh
    source decide/install.sh
    build_install_plan >output/install.sh
    info "Install script generated: output/install.sh"
    info "Review it, then run it inside the Arch ISO (QEMU): bash output/install.sh"
    cat output/install.sh
}

# Interactive layout editor: builds output/layout.txt with custom partitions
# (separate /home, custom sizes...). Non-interactive: shows the current plan.
cmd_layout() {
    if [[ ! -f output/facts.txt ]]; then
        error "output/facts.txt not found — run './main.sh detect' first"
        return 1
    fi
    source output/facts.txt
    source decide/partition.sh

    if [[ ! -t 0 ]]; then
        warn "Not a terminal — showing the current layout instead"
        cmd_partition
        return 0
    fi

    # Start from an existing layout when there is one
    local swap="auto" root_fs="" extras=()
    local mp="" f="" size="" ans=""
    if [[ -f output/layout.txt ]]; then
        info "Editing existing output/layout.txt"
        while read -r mp f size; do
            [[ "$mp" == \#* || -z "$mp" ]] && continue
            case "$mp" in
            "[swap]") swap="$size" ;;
            "/") root_fs="$f" ;;
            /*) extras+=("$mp|$f|$size") ;;
            esac
        done <output/layout.txt
    fi

    # 1. Swap
    while true; do
        printf 'Swap? [auto / size like 8G / none] (default: %s): ' "${swap:-none}"
        read -r ans
        [[ -n "$ans" ]] && swap="$ans"
        if [[ "$swap" =~ ^(auto|none)$ || "$swap" =~ ^[0-9]+[MG]$ ]]; then
            break
        fi
        warn "Invalid swap: $swap (use auto, none or a size like 8G)"
    done

    # 2. Root filesystem
    [[ -z "$root_fs" ]] && root_fs=$(default_fs)
    while true; do
        printf 'Root filesystem? [btrfs/ext4] (default: %s): ' "$root_fs"
        read -r ans
        [[ -n "$ans" ]] && root_fs="$ans"
        if [[ "$root_fs" == "btrfs" || "$root_fs" == "ext4" ]]; then
            break
        fi
        warn "Invalid filesystem: $root_fs (use btrfs or ext4)"
    done

    # 3. Extra data partitions
    while true; do
        printf 'Add a data partition? mount point (e.g. /home) or empty to finish: '
        read -r mp
        [[ -z "$mp" ]] && break
        if [[ "$mp" != /* || "$mp" == "/" || "$mp" == "/efi" ]]; then
            warn "Invalid mount point: $mp (must be like /home)"
            continue
        fi
        printf '  Filesystem [btrfs/ext4] (default: %s): ' "$root_fs"
        read -r f
        [[ -z "$f" ]] && f="$root_fs"
        if [[ "$f" != "btrfs" && "$f" != "ext4" ]]; then
            warn "Invalid filesystem: $f (use btrfs or ext4)"
            continue
        fi
        printf '  Size in G (e.g. 100, or rest): '
        read -r size
        if ! [[ "$size" =~ ^[0-9]+$ || "$size" == "rest" ]]; then
            warn "Invalid size: $size (use a number of GB or rest)"
            continue
        fi
        extras+=("$mp|$f|${size}G")
    done

    # 4. Write layout.txt
    {
        echo "# Custom layout generated by ./main.sh layout — edit freely"
        echo "# Format: <mount> <filesystem> <size|rest>  (the boot partition is automatic)"
        if [[ "$swap" == "auto" ]]; then
            echo "[swap] linux-swap auto"
        elif [[ "$swap" != "none" ]]; then
            echo "[swap] linux-swap $swap"
        fi
        for e in "${extras[@]}"; do
            IFS='|' read -r mp f size <<<"$e"
            echo "$mp $f $size"
        done
        echo "/ $root_fs rest"
    } >output/layout.txt
    log "Layout written to output/layout.txt"
    cmd_partition
}

case "$1" in
detect) cmd_detect ;;
decide) cmd_decide ;;
search) cmd_search "$2" ;;
check) cmd_check ;;
clean) cmd_clean ;;
all) cmd_all ;;
partition) cmd_partition ;;
install) cmd_install ;;
layout) cmd_layout ;;
*)
    usage
    exit 1
    ;;
esac
