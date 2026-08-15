#!/usr/bin/env bash

set -euo pipefail

RESET_API_KEY="${RESET_API_KEY:-0}"
API_KEYS="${API_KEYS:-0}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --reset-api-key)
                RESET_API_KEY=1
                shift
                ;;
            --api-keys)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    API_KEYS="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            *) # unknown flag/switch
                POSITIONAL+=("$1")
                shift
                ;;
        esac
    done
}

main() {
    if ! command -v docker > /dev/null 2>&1; then
        echo 'Docker is not installed.' >&2
        return 1
    fi

    docker build \
        -t 'copilot-api-config:latest' \
        '.'

    docker run \
        --rm \
        -e "RESET_API_KEY=$RESET_API_KEY" \
        -e "API_KEYS=$API_KEYS" \
        -v "$HOME/.copilot-api:/root/.copilot-api" \
        'copilot-api-config:latest'
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
