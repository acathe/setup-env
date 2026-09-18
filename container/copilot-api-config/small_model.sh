#!/usr/bin/env bash

set -euo pipefail

COPILOT_API_CONFIG_SMALL_MODEL="${COPILOT_API_CONFIG_SMALL_MODEL:-}"

set_small_model() {
    local model="$1"
    local tmp
    tmp="$(mktemp)"

    jq --arg model "$model" \
        '.smallModel = $model
        | .alphaSearchModel = $model
        | .messageApiWebSearchModel = $model
        | reduce ["extraPrompts", "modelReasoningEfforts"][] as $key (.;
            if (.[$key] | has("gpt-5-mini") and (has($model) | not)) then
                .[$key][$model] = .[$key]["gpt-5-mini"]
            else
                .
            end
        )' \
        "$HOME/.copilot-data/config.json" > "$tmp"
    cp "$tmp" "$HOME/.copilot-data/config.json"
}

main() {
    if [[ -n $COPILOT_API_CONFIG_SMALL_MODEL ]]; then
        set_small_model "$COPILOT_API_CONFIG_SMALL_MODEL"
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
