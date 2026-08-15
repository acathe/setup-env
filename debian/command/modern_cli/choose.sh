#!/usr/bin/env bash

set -euo pipefail

main() {
    local tmp
    tmp="$(mktemp -d)"

    curl -fsSL -o "$tmp/choose" \
        'https://github.com/theryangeary/choose/releases/latest/download/choose-x86_64-unknown-linux-gnu'

    install -Dm 755 "$tmp/choose" "$HOME/.local/bin/choose"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
