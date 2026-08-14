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

    {
        echo ''
        echo '# Mouse wheel'
        echo 'bind -n WheelUpPane {'
        echo '    if -F "#{||:#{pane_in_mode},#{mouse_any_flag}}" {'
        echo '        send -M'
        echo '    } {'
        echo '        if -F "#{alternate_on}" { send-keys Up } { copy-mode -e }'
        echo '    }'
        echo '}'
        echo 'bind -n WheelDownPane {'
        echo '    if -F "#{||:#{pane_in_mode},#{mouse_any_flag}}" {'
        echo '        send -M'
        echo '    } {'
        echo '        if -F "#{alternate_on}" { send-keys Down }'
        echo '    }'
        echo '}'

        if [[ $APP_CLAUDE == '1' ]]; then
            echo ''
            echo '# Claude Code'
            echo 'set -g allow-passthrough on'
            echo 'set -s extended-keys on'
            echo 'set -as terminal-features "xterm*:extkeys"'
        fi
    } >> "$HOME/.config/tmux/tmux.conf.local"
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
