#!/usr/bin/env bash

set -euo pipefail

COMMAND_MODERN_CLI="${COMMAND_MODERN_CLI:-0}"
CODE_MARKDOWN="${CODE_MARKDOWN:-0}"

install_plugins() {
    if [[ $CODE_MARKDOWN == '1' ]]; then
        ya pkg add 'alberti42/faster-piper'
    fi

    if [[ $COMMAND_MODERN_CLI == '1' ]]; then
        ya pkg add 'yazi-rs/plugins:piper'
    fi

    ya pkg add 'yazi-rs/plugins:git'
    ya pkg add 'yazi-rs/plugins:toggle-pane'
    ya pkg add 'yazi-rs/plugins:smart-enter'
    ya pkg add 'yazi-rs/plugins:smart-filter'
    ya pkg add 'yazi-rs/plugins:smart-paste'
}

install_config() {
    bash './yazi.toml.sh' "$@"
    install -Dm 644 './init.lua' "$HOME/.config/yazi/init.lua"
    install -Dm 644 './keymap.toml' "$HOME/.config/yazi/keymap.toml"
}

main() {
    brew install -q 'yazi'

    install_plugins
    install_config "$@"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
