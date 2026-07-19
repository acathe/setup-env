#!/usr/bin/env bash

set -euo pipefail

install_oh_my_tmux() {
    mkdir -p "$HOME/.config"

    local install_sh
    install_sh="$(mktemp)"
    curl -fsSL "https://raw.githubusercontent.com/gpakosz/.tmux/master/install.sh" -o "$install_sh"
    bash "$install_sh" < /dev/null
}

main() {
    sudo apt update
    sudo apt install -y tmux

    install_oh_my_tmux

    sed -i 's/^#set -g mouse on$/set -g mouse on/' "$HOME/.config/tmux/tmux.conf.local"
    sed -i 's/^#set -g history-limit .*/set -g history-limit 10000/' "$HOME/.config/tmux/tmux.conf.local"
    sed -i '/^plugins=(/s/)/ tmux)/' "$HOME/.zshrc"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
