#!/usr/bin/env bash

set -euo pipefail

main() {
    sudo apt-get update
    sudo apt-get install -y \
        jq \
        unzip

    install -Dm 644 './lesskey' "$HOME/.config/lesskey"
    install -Dm 644 './nanorc' "$HOME/.config/nano/nanorc"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
