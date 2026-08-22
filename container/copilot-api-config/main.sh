#!/usr/bin/env bash

set -euo pipefail

export CLEAR_API_KEYS="${CLEAR_API_KEYS:-0}"
export API_KEY_GENERATION_COUNT="${API_KEY_GENERATION_COUNT:-0}"
export API_KEY_TO_ADD="${API_KEY_TO_ADD:-}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --clear-api-keys | --reset-api-key)
                CLEAR_API_KEYS=1
                shift
                ;;
            --generate-api-keys | --api-keys)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    echo "$1 requires a value." >&2
                    return 1
                else
                    API_KEY_GENERATION_COUNT="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --add-api-key=*)
                API_KEY_TO_ADD="${1#*=}"
                if [[ -z $API_KEY_TO_ADD ]]; then
                    echo '--add-api-key requires a non-empty value.' >&2
                    return 1
                fi
                shift
                ;;
            --add-api-key)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    echo '--add-api-key requires a value.' >&2
                    return 1
                elif [[ -z $2 ]]; then
                    echo '--add-api-key requires a non-empty value.' >&2
                    return 1
                else
                    API_KEY_TO_ADD="$2"
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

main() {
    if ! validate_options; then
        return 1
    fi

    if ! command -v docker > /dev/null 2>&1; then
        echo 'Docker is not installed.' >&2
        return 1
    fi

    docker build \
        -t 'copilot-api-config:latest' \
        '.'

    docker run \
        --rm \
        --env CLEAR_API_KEYS \
        --env API_KEY_GENERATION_COUNT \
        --env API_KEY_TO_ADD \
        -v "$HOME/.copilot-api:/root/.copilot-api" \
        'copilot-api-config:latest'
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
