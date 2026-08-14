#!/usr/bin/env bash

#Orchestrator

set -uo pipefail
source lib/common.sh

usage() {
    echo "Usage: $0 <detect|decide|search|check|all>"
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
}

case "$1" in
detect) cmd_detect ;;
decide) cmd_decide ;;
*)
    usage
    exit 1
    ;;
esac
