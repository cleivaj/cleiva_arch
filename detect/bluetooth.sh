#!/usr/bin/env bash

#Detect Bluetooth

set -u

if compgen -G "/sys/class/bluetooth/hci*" >/dev/null 2>&1; then
    echo "HAS_BLUETOOTH=yes"
else
    echo "HAS_BLUETOOTH=no"
fi
