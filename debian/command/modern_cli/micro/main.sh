#!/usr/bin/env bash

set -euo pipefail

main() {
    micro -plugin install detectindent

    install -Dm 644 './settings.json' "$HOME/.config/micro/settings.json"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
