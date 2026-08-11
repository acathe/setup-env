#!/usr/bin/env bash

set -euo pipefail

APP_CLAUDE="${APP_CLAUDE:-0}"
COMMAND_UTILS="${COMMAND_UTILS:-0}"

install_oh_my_tmux() {
    mkdir -p "$HOME/.config"

    local install_sh
    install_sh="$(mktemp)"
    curl -fsSL "https://raw.githubusercontent.com/gpakosz/.tmux/master/install.sh" -o "$install_sh"
    bash "$install_sh" < /dev/null
}

install_sesh() {
    curl -fsSL "https://github.com/joshmedeski/sesh/releases/latest/download/sesh_Linux_x86_64.tar.gz" \
        | sudo tar -xzf - -C /usr/local/bin sesh
}

configure_tmux() {
    local conf="$HOME/.config/tmux/tmux.conf.local"

    sed -i 's/^#set -g mouse on$/set -g mouse on/' "$conf"
    sed -i 's/^#set -g history-limit .*/set -g history-limit 50000/' "$conf"

    if [[ $COMMAND_UTILS == "1" ]]; then
        {
            echo ''
            echo 'set -g detach-on-destroy off'
            echo 'bind-key T display-popup -w 80% -h 70% -E "sesh picker"'
        } >> "$conf"
    fi

    if [[ $APP_CLAUDE == "1" ]]; then
        {
            echo ''
            echo '# Claude Code'
            echo 'set -g allow-passthrough on'
            echo 'set -s extended-keys on'
            echo "set -as terminal-features 'xterm*:extkeys'"
        } >> "$conf"
    fi
}

main() {
    sudo apt-get update
    sudo apt-get install -y tmux

    install_oh_my_tmux

    if [[ $COMMAND_UTILS == "1" ]]; then
        install_sesh
    fi

    configure_tmux

    sed -i '/^plugins=(/s/)/ tmux)/' "$HOME/.zshrc"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
