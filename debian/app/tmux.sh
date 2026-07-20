#!/usr/bin/env bash

set -euo pipefail

AGENT_CLAUDE="${AGENT_CLAUDE:-0}"

install_oh_my_tmux() {
    mkdir -p "$HOME/.config"

    local install_sh
    install_sh="$(mktemp)"
    curl -fsSL "https://raw.githubusercontent.com/gpakosz/.tmux/master/install.sh" -o "$install_sh"
    bash "$install_sh" < /dev/null
}

configure_tmux() {
    local conf="$HOME/.config/tmux/tmux.conf.local"

    sed -i 's/^#set -g mouse on$/set -g mouse on/' "$conf"
    sed -i 's/^#set -g history-limit .*/set -g history-limit 10000/' "$conf"

    if [[ $AGENT_CLAUDE == "1" ]]; then
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
    configure_tmux

    sed -i '/^plugins=(/s/)/ tmux)/' "$HOME/.zshrc"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
