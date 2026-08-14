#!/usr/bin/env bash
#Detect cpu vendor

-set u

VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $NF}')

case "$VENDOR" in
GenuineIntel) echo "CPU_VENDOR=intel" ;;
AuthenticAMD) echo "CPU_VENDOR=amd" ;;
*) echo "CPU_VENDOR=unknown" ;;
esac
