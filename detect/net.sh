#!/usr/bin/env bash

#Detect Net

set -u

if compgen -G "/sys/class/net/*/wireless" >/dev/null 2>&1; then
    echo "NET_WIFI=yes"
else
    echo "NET_WIFI=no"
fi

if command -v curl >/dev/null 2>&1 && curl -s --max-time 5 -o /dev/null https://1.1.1.1; then
    echo "NET_ONLINE=yes"
else
    echo "NET_ONLINE=no"
fi
