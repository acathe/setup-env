#!/usr/bin/env bash

set -euo pipefail

CLEAR_API_KEYS="${CLEAR_API_KEYS:-0}"
API_KEY_GENERATION_COUNT="${API_KEY_GENERATION_COUNT:-0}"
API_KEY_TO_ADD="${API_KEY_TO_ADD:-}"

validate_options() {
    if [[ ! $CLEAR_API_KEYS =~ ^[01]$ ]]; then
        echo 'CLEAR_API_KEYS must be 0 or 1.' >&2
        return 1
    fi

    if [[ ! $API_KEY_GENERATION_COUNT =~ ^(0|[1-9][0-9]?|100)$ ]]; then
        echo 'API key generation count must be an integer from 0 to 100.' >&2
        return 1
    fi
}

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

    printf '%s' "$api_key" \
        | jq --rawfile api_key /dev/stdin \
            '.auth.apiKeys += [$api_key]' \
            "$HOME/.copilot-api/config.json" > "$tmp"
    cp "$tmp" "$HOME/.copilot-api/config.json"
}

disable_responses_api_websocket() {
    local tmp
    tmp="$(mktemp)"

    jq '.useResponsesApiWebSocket = false' \
        "$HOME/.copilot-api/config.json" > "$tmp"
    cp "$tmp" "$HOME/.copilot-api/config.json"
}

main() {
    if ! validate_options; then
        return 1
    fi

    disable_responses_api_websocket

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
