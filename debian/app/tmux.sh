#!/usr/bin/env bash

set -euo pipefail

APP_CLAUDE="${APP_CLAUDE:-0}"

install_oh_my_tmux() {
    mkdir -p "$HOME/.config"

    local install_sh
    install_sh="$(mktemp)"
    curl -fsSL 'https://raw.githubusercontent.com/gpakosz/.tmux/master/install.sh' -o "$install_sh"
    bash "$install_sh" < /dev/null
}

configure_tmux() {
    sed -i 's/^#set -g mouse on$/set -g mouse on/' "$HOME/.config/tmux/tmux.conf.local"
    sed -i 's/^#set -g history-limit .*/set -g history-limit 10000/' "$HOME/.config/tmux/tmux.conf.local"

    if [[ $APP_CLAUDE == '1' ]]; then
        {
            cat << 'EOF'

# Claude Code
set -g allow-passthrough on
set -s extended-keys on
set -as terminal-features "xterm*:extkeys"
EOF
        } >> "$HOME/.config/tmux/tmux.conf.local"
    fi
}

main() {
    sudo apt-get update
    sudo apt-get install -y tmux

    install_oh_my_tmux
    configure_tmux
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
