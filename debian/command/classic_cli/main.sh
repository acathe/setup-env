#!/usr/bin/env bash

set -euo pipefail

COMMAND_MODERN_CLI="${COMMAND_MODERN_CLI:-0}"

main() {
    install -Dm 644 './lesskey' "$HOME/.config/lesskey"
    if [[ $COMMAND_MODERN_CLI != '1' ]]; then
        install -Dm 755 './nanom' "$HOME/.local/bin/nanom"
        install -Dm 644 './nanorc' "$HOME/.config/nano/nanorc"
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
