#!/usr/bin/env bash

set -euo pipefail

COPILOT_API_CONFIG_CLEAR_API_KEYS="${COPILOT_API_CONFIG_CLEAR_API_KEYS:-0}"
COPILOT_API_CONFIG_GENERATE_API_KEYS="${COPILOT_API_CONFIG_GENERATE_API_KEYS:-0}"
COPILOT_API_CONFIG_ADD_API_KEY="${COPILOT_API_CONFIG_ADD_API_KEY:-}"

clear_api_keys() {
    local tmp
    tmp="$(mktemp)"

    jq '.auth.apiKeys = []' \
        "$HOME/.copilot-data/config.json" > "$tmp"
    cp "$tmp" "$HOME/.copilot-data/config.json"
}

add_api_key() {
    local api_key="$1"
    local tmp
    tmp="$(mktemp)"

    jq --arg api_key "$api_key" \
        '.auth.apiKeys += [$api_key]' \
        "$HOME/.copilot-data/config.json" > "$tmp"
    cp "$tmp" "$HOME/.copilot-data/config.json"
}

main() {
    if [[ $COPILOT_API_CONFIG_CLEAR_API_KEYS == '1' ]]; then
        clear_api_keys
    fi

    local i
    for ((i = 0; i < COPILOT_API_CONFIG_GENERATE_API_KEYS; i++)); do
        add_api_key "$(openssl rand -hex 32)"
    done

    if [[ -n $COPILOT_API_CONFIG_ADD_API_KEY ]]; then
        add_api_key "$COPILOT_API_CONFIG_ADD_API_KEY"
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
