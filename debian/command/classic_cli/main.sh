#!/usr/bin/env bash

set -euo pipefail

COMMAND_MODERN_CLI="${COMMAND_MODERN_CLI:-0}"

main() {
    # less
    install -Dm 644 './less.lesskey' "$HOME/.config/lesskey"

    # nano
    if [[ $COMMAND_MODERN_CLI != '1' ]]; then
        install -D './nanom' "$HOME/.local/bin/nanom"
        install -Dm 644 './nano.nanorc' "$HOME/.config/nano/nanorc"
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
