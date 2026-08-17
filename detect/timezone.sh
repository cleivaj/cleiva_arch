#!/usr/bin/env bash

#Detect Timezone

set -u

TZ=$(readlink -f /etc/localtime 2>/dev/null | sed 's|^/usr/share/zoneinfo/||')

# If it isn't a real zoneinfo path (e.g. /etc/localtime is a copy, or missing)
# the value keeps a leading slash → not a valid zone → fall back to UTC.
[[ "$TZ" == /* || -z "$TZ" ]] && TZ=UTC

echo "TIMEZONE=$TZ"
