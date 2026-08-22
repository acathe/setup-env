#!/usr/bin/env bash

set -euo pipefail

CLEAR_API_KEYS="${CLEAR_API_KEYS:-0}"
API_KEY_GENERATION_COUNT="${API_KEY_GENERATION_COUNT:-0}"
API_KEY_TO_ADD="${API_KEY_TO_ADD:-}"

clear_api_keys() {
    local tmp
    tmp="$(mktemp)"

    jq '.auth.apiKeys = []' \
        "$HOME/.copilot-api/config.json" > "$tmp"
    cp "$tmp" "$HOME/.copilot-api/config.json"
}

add_api_key() {
    local api_key="$1"
    local tmp
    tmp="$(mktemp)"

    jq --arg api_key "$api_key" \
        '.auth.apiKeys += [$api_key]' \
        "$HOME/.copilot-api/config.json" > "$tmp"
    cp "$tmp" "$HOME/.copilot-api/config.json"
}

main() {
    if [[ $CLEAR_API_KEYS == '1' ]]; then
        clear_api_keys
    fi

    local i
    for ((i = 0; i < API_KEY_GENERATION_COUNT; i++)); do
        add_api_key "$(openssl rand -hex 32)"
    done

    if [[ -n $API_KEY_TO_ADD ]]; then
        add_api_key "$API_KEY_TO_ADD"
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
