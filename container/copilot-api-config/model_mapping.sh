#!/usr/bin/env bash

set -euo pipefail

COPILOT_API_CONFIG_MODEL_MAPPING_KEY="${COPILOT_API_CONFIG_MODEL_MAPPING_KEY:-}"
COPILOT_API_CONFIG_MODEL_MAPPING_VALUE="${COPILOT_API_CONFIG_MODEL_MAPPING_VALUE:-}"

set_model_mapping() {
    local key="$1" value="$2"
    local tmp
    tmp="$(mktemp)"

    jq --arg key "$key" --arg value "$value" \
        '.modelMappings[$key] = $value' \
        "$HOME/.copilot-data/config.json" > "$tmp"
    cp "$tmp" "$HOME/.copilot-data/config.json"
}

main() {
    if [[ -n $COPILOT_API_CONFIG_MODEL_MAPPING_KEY && -n $COPILOT_API_CONFIG_MODEL_MAPPING_VALUE ]]; then
        set_model_mapping "$COPILOT_API_CONFIG_MODEL_MAPPING_KEY" "$COPILOT_API_CONFIG_MODEL_MAPPING_VALUE"
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
