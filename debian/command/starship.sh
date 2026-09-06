#!/usr/bin/env bash

set -euo pipefail

main() {
    brew install -q 'starship'

    mkdir -p "$HOME/.config"
    starship preset nerd-font-symbols -o "$HOME/.config/starship.toml"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
