#!/usr/bin/env bash

set -euo pipefail

COMMAND_MODERN_CLI="${COMMAND_MODERN_CLI:-0}"
CODE_MARKDOWN="${CODE_MARKDOWN:-0}"

add_repo() {
    curl -fsSL 'https://yazi-rs.github.io/builds/yazi-keyring.gpg' \
        | sudo tee '/usr/share/keyrings/yazi-keyring.gpg' > /dev/null
    echo 'deb [signed-by=/usr/share/keyrings/yazi-keyring.gpg] https://yazi-rs.github.io/builds/ stable main' \
        | sudo tee '/etc/apt/sources.list.d/yazi.list' > /dev/null
}

install_plugins() {
    export PATH="$HOME/.local/bin:$PATH"

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
    add_repo
    sudo apt-get update
    sudo apt-get install -y file yazi

    install_plugins
    install_config "$@"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
