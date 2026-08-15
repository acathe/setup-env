#!/usr/bin/env bash

set -euo pipefail

RESET_API_KEY="${RESET_API_KEY:-0}"
API_KEYS="${API_KEYS:-0}"

reset_api_key() {
    local tmp
    tmp="$(mktemp)"

    jq '.auth.apiKeys = []' \
        "$HOME/.copilot-api/config.json" > "$tmp"
    cp "$tmp" "$HOME/.copilot-api/config.json"
}

add_api_keys() {
    local tmp
    tmp="$(mktemp)"

    jq --arg api_key "$(openssl rand -hex 32)" \
        '.auth.apiKeys += [$api_key]' \
        "$HOME/.copilot-api/config.json" > "$tmp"
    cp "$tmp" "$HOME/.copilot-api/config.json"
}

main() {
    if [[ $RESET_API_KEY == '1' ]]; then
        reset_api_key
    fi

    local i
    for ((i = 0; i < API_KEYS; i++)); do
        add_api_keys
    done
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
