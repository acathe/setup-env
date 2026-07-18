#!/usr/bin/env bash

set -euo pipefail

CLI_CLAUDE_INSTALL="${CLI_CLAUDE_INSTALL:-0}"
CLI_COPILOT_API="${CLI_COPILOT_API:-0}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --cli-claude-install)
                CLI_CLAUDE_INSTALL=1
                shift
                ;;
            --cli-copilot-api)
                CLI_COPILOT_API=1
                shift
                ;;
            *) # unknown flag/switch
                POSITIONAL+=("$1")
                shift
                ;;
        esac
    done
}

install_claude() {
    if ! command -v curl > /dev/null 2>&1; then
        echo "curl is required to install Claude Code." >&2
        return 1
    fi

    curl -fsSL "https://claude.ai/install.sh" | bash
}

main() {
    if [[ $CLI_CLAUDE_INSTALL == "1" ]]; then
        install_claude
    fi

    if [[ $CLI_COPILOT_API == "1" ]]; then
        bash "./copilot_api.sh" "$@"
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
