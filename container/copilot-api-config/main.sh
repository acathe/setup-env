#!/usr/bin/env bash

set -euo pipefail

COPILOT_API_CONFIG_CLEAR_API_KEYS="${COPILOT_API_CONFIG_CLEAR_API_KEYS:-0}"
COPILOT_API_CONFIG_GENERATE_API_KEYS="${COPILOT_API_CONFIG_GENERATE_API_KEYS:-0}"
COPILOT_API_CONFIG_ADD_API_KEY="${COPILOT_API_CONFIG_ADD_API_KEY:-}"
COPILOT_API_CONFIG_MODEL_MAPPING_KEY="${COPILOT_API_CONFIG_MODEL_MAPPING_KEY:-}"
COPILOT_API_CONFIG_MODEL_MAPPING_VALUE="${COPILOT_API_CONFIG_MODEL_MAPPING_VALUE:-}"
COPILOT_API_CONFIG_SMALL_MODEL="${COPILOT_API_CONFIG_SMALL_MODEL:-}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --clear-api-keys)
                COPILOT_API_CONFIG_CLEAR_API_KEYS=1
                shift
                ;;
            --generate-api-keys)
                numOfArgs=1
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    COPILOT_API_CONFIG_GENERATE_API_KEYS="$2"
                    shift $((numOfArgs + 1))
                fi
                ;;
            --add-api-key)
                numOfArgs=1
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    COPILOT_API_CONFIG_ADD_API_KEY="$2"
                    shift $((numOfArgs + 1))
                fi
                ;;
            --model-mapping)
                numOfArgs=2
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    COPILOT_API_CONFIG_MODEL_MAPPING_KEY="$2"
                    COPILOT_API_CONFIG_MODEL_MAPPING_VALUE="$3"
                    shift $((numOfArgs + 1))
                fi
                ;;
            --small-model)
                numOfArgs=1
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    COPILOT_API_CONFIG_SMALL_MODEL="$2"
                    shift $((numOfArgs + 1))
                fi
                ;;
            *)
                POSITIONAL+=("$1")
                shift
                ;;
        esac
    done
}

main() {
    docker build \
        -qt 'copilot-api-config' \
        '.'

    docker run \
        -q \
        --rm \
        -e "COPILOT_API_CONFIG_CLEAR_API_KEYS=$COPILOT_API_CONFIG_CLEAR_API_KEYS" \
        -e "COPILOT_API_CONFIG_GENERATE_API_KEYS=$COPILOT_API_CONFIG_GENERATE_API_KEYS" \
        -e "COPILOT_API_CONFIG_ADD_API_KEY=$COPILOT_API_CONFIG_ADD_API_KEY" \
        -e "COPILOT_API_CONFIG_MODEL_MAPPING_KEY=$COPILOT_API_CONFIG_MODEL_MAPPING_KEY" \
        -e "COPILOT_API_CONFIG_MODEL_MAPPING_VALUE=$COPILOT_API_CONFIG_MODEL_MAPPING_VALUE" \
        -e "COPILOT_API_CONFIG_SMALL_MODEL=$COPILOT_API_CONFIG_SMALL_MODEL" \
        -v "$HOME/.copilot-data:/root/.copilot-data" \
        'copilot-api-config'
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}"
    main "$@"
fi
