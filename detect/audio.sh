#!/usr/bin/env bash

#Detect Audio

set -u

if command -v lspci >/dev/null 2>&1 && lspci 2>/dev/null | grep -qi 'audio'; then
    echo "HAS_AUDIO=yes"
else
    echo "HAS_AUDIO=no"
fi
