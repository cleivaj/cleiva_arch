#!/usr/bin/env bash

#Orchestrator

set -uo pipefail
source lib/common.sh
source lib/api.sh

usage() {
    echo "Usage: $0 <detect|decide|search|check|all|install>"
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
    rm -r output/*.txt output/*.md
    info "Output cleaned"
}

cmd_all() {
    cmd_detect
    cmd_decide
    cmd_check
}

cmd_partition() {
    source output/facts.txt
    source decide/partition.sh
    build_partitions >output/partition.txt
    info "Partition plan:"
    cat output/partition.txt
}

cmd_install() {
    source output/facts.txt
    source decide/partition.sh
    source decide/install.sh
    build_install_plan >output/install.sh
    info "Install script generated: output/install.sh"
    cat output/install.sh
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
*)
    usage
    exit 1
    ;;
esac
