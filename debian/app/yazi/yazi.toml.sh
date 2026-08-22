#!/usr/bin/env bash

set -euo pipefail

COMMAND_MODERN_CLI="${COMMAND_MODERN_CLI:-0}"
CODE_MARKDOWN="${CODE_MARKDOWN:-0}"

main() {
    mkdir -p "$HOME/.config/yazi"
    {
        if [[ $CODE_MARKDOWN == '1' ]]; then
            cat './yazi.toml/markdown.yazi.toml'
            echo
        fi

        if [[ $COMMAND_MODERN_CLI == '1' ]]; then
            cat './yazi.toml/bat.yazi.toml'
            echo
        fi

        cat './yazi.toml/git.yazi.toml'
    } > "$HOME/.config/yazi/yazi.toml"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
