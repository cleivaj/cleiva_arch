#!/usr/bin/env bash

#Format logging

if [[ -t 1 ]]; then
    C_RED='\033[0;31m'
    C_GREEN='\033[0;32m'
    C_YELLOW='\033[0;33m'
    C_BLUE='\033[0;34m'
    C_MAGENTA='\033[0;35m'
    C_CYAN='\033[0;36m'
    C_BOLD='\033[1m'
    C_RESET='\033[0m'
else
    C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_MAGENTA='' C_CYAN='' C_BOLD='' C_RESET=''
fi

log() { printf '%b[+]%b %s\n' "$C_GREEN" "$C_RESET" "$*"; }
info() { printf '%b[*]%b %s\n' "$C_BLUE" "$C_RESET" "$*"; }
warn() { printf '%b[!]%b %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
error() { printf '%b[x]%b %s\n' "$C_RED" "$C_RESET" "$*"; }

have() { command -v "$1" >/dev/null 2>&1; }

# Idempotently write a KEY=VALUE line to output/facts.txt: replaces an existing
# key instead of appending a duplicate. Values with whitespace are double-quoted
# so the file stays safe to `source`.
set_fact() {
    local key="$1" value="$2"
    mkdir -p output
    if [[ -f output/facts.txt ]] && grep -q "^${key}=" output/facts.txt; then
        grep -v "^${key}=" output/facts.txt > output/facts.txt.tmp
        mv output/facts.txt.tmp output/facts.txt
    fi
    if [[ "$value" == *[[:space:]]* ]]; then
        printf '%s="%s"\n' "$key" "$value" >> output/facts.txt
    else
        printf '%s=%s\n' "$key" "$value" >> output/facts.txt
    fi
}

# Status symbols shared by init.sh and lib/steps.sh
OK="${C_GREEN}[✓]${C_RESET}"
ERROR="${C_RED}[✗]${C_RESET}"
INFO="${C_BLUE}[ℹ]${C_RESET}"
WARN="${C_YELLOW}[⚠]${C_RESET}"
ACTION="${C_CYAN}[→]${C_RESET}"
BOLD="${C_BOLD}"
RESET="${C_RESET}"
