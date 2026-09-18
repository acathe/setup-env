#!/usr/bin/env bash

set -euo pipefail

CLEAR_API_KEYS="${CLEAR_API_KEYS:-0}"
API_KEY_GENERATION_COUNT="${API_KEY_GENERATION_COUNT:-0}"
API_KEY_TO_ADD="${API_KEY_TO_ADD:-}"
MODEL_MAPPING_KEY="${MODEL_MAPPING_KEY:-}"
MODEL_MAPPING_VALUE="${MODEL_MAPPING_VALUE:-}"
SMALL_MODEL="${SMALL_MODEL:-}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --clear-api-keys | --reset-api-key)
                CLEAR_API_KEYS=1
                shift
                ;;
            --generate-api-keys | --api-keys)
                numOfArgs=1
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    API_KEY_GENERATION_COUNT="$2"
                    shift $((numOfArgs + 1))
                fi
                ;;
            --add-api-key)
                numOfArgs=1
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    API_KEY_TO_ADD="$2"
                    shift $((numOfArgs + 1))
                fi
                ;;
            --model-mapping)
                numOfArgs=2
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    MODEL_MAPPING_KEY="$2"
                    MODEL_MAPPING_VALUE="$3"
                    shift $((numOfArgs + 1))
                fi
                ;;
            --small-model)
                numOfArgs=1
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    SMALL_MODEL="$2"
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
        -e "CLEAR_API_KEYS=$CLEAR_API_KEYS" \
        -e "API_KEY_GENERATION_COUNT=$API_KEY_GENERATION_COUNT" \
        -e "API_KEY_TO_ADD=$API_KEY_TO_ADD" \
        -e "MODEL_MAPPING_KEY=$MODEL_MAPPING_KEY" \
        -e "MODEL_MAPPING_VALUE=$MODEL_MAPPING_VALUE" \
        -e "SMALL_MODEL=$SMALL_MODEL" \
        -v "$HOME/.copilot-data:/root/.copilot-data" \
        'copilot-api-config'
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}"
    main "$@"
fi
