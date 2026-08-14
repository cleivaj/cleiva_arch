#!/usr/bin/env bash

#Format logging

if [[ -t 1 ]]; then
    C_RED='\033[0;31m'
    C_GREEN='\033[0;32m'
    C_YELLOW='\033[0;33m'
    C_BLUE='\033[0;34m'
    C_RESET='\033[0m'
else
    C_RED=''
    C_GREEN=''
    C_YELLOW=''
    C_BLUE=''
    C_RESET=''
fi

log() { printf '%b[+]%b %s\n' "$C_GREEN" "$C_RESET" "$*"; }
info() { printf '%b[*]%b %s\n' "$C_BLUE" "$C_RESET" "$*"; }
warn() { printf '%b[!]%b %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
error() { printf '%b[x]%b %s\n' "$C_RED" "$C_RESET" "$*"; }

have() { command -v "$1" >/dev/null 2>&1; }
