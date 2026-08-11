#!/usr/bin/env bash

set -euo pipefail

APP_CLAUDE_COPILOT_API="${APP_CLAUDE_COPILOT_API:-0}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --app-claude-copilot-api)
                APP_CLAUDE_COPILOT_API=1
                shift # shift once since flags have no values
                ;;
            *) # unknown flag/switch
                POSITIONAL+=("$1")
                shift
                ;;
        esac
    done
}

install_claude_code() {
    if ! command -v curl > /dev/null 2>&1; then
        echo 'curl is required to install Claude Code.' >&2
        return 1
    fi

    curl -fsSL 'https://claude.ai/install.sh' | bash
}

main() {
    install_claude_code

    if [[ $APP_CLAUDE_COPILOT_API == '1' ]]; then
        bash './copilot_api/main.sh' "$@"
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
