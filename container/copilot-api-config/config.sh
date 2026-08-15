#!/usr/bin/env bash

set -euo pipefail

main() {
    local api_key tmp
    api_key="$(openssl rand -hex 32)"
    tmp="$(mktemp)"

    jq --arg api_key "$api_key" \
        '.auth.apiKeys += [$api_key]' \
        "$HOME/.copilot-api/config.json" > "$tmp"
    cp "$tmp" "$HOME/.copilot-api/config.json"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
