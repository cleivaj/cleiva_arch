#!/usr/bin/env bash
#Detect ram

set -u

RAM_GB=$(free -g 2>/dev/null | awk '/^Mem:/{print $2}')
echo "RAM_GB=${RAM_GB:-0}"