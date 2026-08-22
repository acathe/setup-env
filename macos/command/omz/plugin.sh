#!/usr/bin/env bash

set -euo pipefail

COMMAND_SSH="${COMMAND_SSH:-0}"

APP_VSCODE="${APP_VSCODE:-0}"

append_plugin() {
    local plugin="$1"
    sed -i '' "/^plugins=(/s/)/ $plugin)/" "$HOME/.zshrc"
}

main() {
    sed -i '' 's/^plugins=(.*)/plugins=(aliases)/' "$HOME/.zshrc"

    append_plugin 'brew'
    append_plugin 'colored-man-pages'
    append_plugin 'command-not-found'
    append_plugin 'copyfile'
    append_plugin 'copypath'
    append_plugin 'dirhistory'
    append_plugin 'extract'
    append_plugin 'fancy-ctrl-z'
    append_plugin 'macos'
    append_plugin 'magic-enter'
    append_plugin 'safe-paste'
    append_plugin 'starship'
    append_plugin 'sudo'
    append_plugin 'universalarchive'
    append_plugin 'z'

    [[ $COMMAND_SSH == '1' ]] && append_plugin 'ssh'
    [[ $APP_VSCODE == '1' ]] && append_plugin 'vscode'

    append_plugin 'update-all-in-one'
    append_plugin 'ohmyzsh-full-autoupdate'
    append_plugin 'you-should-use'
    append_plugin 'zsh-autosuggestions'
    append_plugin 'zsh-syntax-highlighting'

    return 0
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
