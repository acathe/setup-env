#!/usr/bin/env bash

set -euo pipefail

main() {
    install -Dm 644 './config' "$HOME/.config/bat/config"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
