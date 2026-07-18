#!/usr/bin/env bash

set -euo pipefail

GATEWAY_COPILOT_API="${GATEWAY_COPILOT_API:-0}"
CLI_CLAUDE="${CLI_CLAUDE:-0}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --gateway-copilot-api)
                GATEWAY_COPILOT_API=1
                shift
                ;;
            --cli-claude)
                CLI_CLAUDE=1
                shift
                ;;
            *) # unknown flag/switch
                POSITIONAL+=("$1")
                shift
                ;;
        esac
    done
}

main() {
    if [[ $GATEWAY_COPILOT_API == "1" ]]; then
        bash "./gateway/copilot_api.sh" "$@"
    fi

    if [[ $CLI_CLAUDE == "1" ]]; then
        bash "./cli/claude/main.sh" "$@"
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
