#!/usr/bin/env bash

set -euo pipefail

setup_less() {
    install -Dm 644 './less.lesskey' "$HOME/.config/lesskey"
}

setup_nano() {
    install -D './nanom' "$HOME/.local/bin/nanom"
    install -Dm 644 './nano.nanorc' "$HOME/.config/nano/nanorc"
}

main() {
    setup_less
    setup_nano
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
