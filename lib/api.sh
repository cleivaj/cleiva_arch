#!/usr/bin/env bash

#api calls

set -u

API_URL="https://archlinux.org/packages/search/json/"

search_pkg() {
    local q="$1"
    if ! have curl; then
        error "Curl is not installed"
        return 1
    fi

    curl -s --fail --max-time 15 "${API_URL}?q=${q}" || return 1

}

pkg_exists() {
    local pkg="$1" json
    json=$(search_pkg "$pkg") || return 2

    if grep -qE "\"pkgname\":[[:space:]]*\"${pkg}\"" <<<"$json"; then
        return 0
    fi

    return 1
}
