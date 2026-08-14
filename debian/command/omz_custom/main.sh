#!/usr/bin/env bash

set -euo pipefail

COMMAND_MODERN_CLI="${COMMAND_MODERN_CLI:-0}"

APP_DOCKER="${APP_DOCKER:-0}"
APP_GIT="${APP_GIT:-0}"
APP_TMUX="${APP_TMUX:-0}"
APP_VSCODE="${APP_VSCODE:-0}"

CODE_GO="${CODE_GO:-0}"
CODE_PYTHON="${CODE_PYTHON:-0}"
CODE_RUST="${CODE_RUST:-0}"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

download_plugin() {
    git clone 'https://github.com/Pilaton/OhMyZsh-full-autoupdate.git' \
        "$ZSH_CUSTOM/plugins/ohmyzsh-full-autoupdate"
    git clone 'https://github.com/Aloxaf/fzf-tab' \
        "$ZSH_CUSTOM/plugins/fzf-tab"
    git clone 'https://github.com/MichaelAquilina/zsh-you-should-use' \
        "$ZSH_CUSTOM/plugins/you-should-use"
    git clone 'https://github.com/zsh-users/zsh-autosuggestions' \
        "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    git clone 'https://github.com/zsh-users/zsh-syntax-highlighting.git' \
        "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
}

append_plugin() {
    local plugin="$1"
    sed -i "/^plugins=(/s/)/ $plugin)/" "$HOME/.zshrc"
}

install_plugin() {
    sed -i 's/^plugins=(.*)/plugins=(aliases)/' "$HOME/.zshrc"

    append_plugin 'colored-man-pages'
    append_plugin 'dirhistory'
    append_plugin 'extract'
    append_plugin 'fancy-ctrl-z'
    append_plugin 'magic-enter'
    append_plugin 'safe-paste'
    append_plugin 'sudo'
    append_plugin 'universalarchive'
    append_plugin 'z'

    [[ $COMMAND_MODERN_CLI == '1' ]] && append_plugin 'eza'
    [[ $COMMAND_MODERN_CLI == '1' ]] && append_plugin 'fzf'
    [[ $COMMAND_MODERN_CLI == '1' ]] && append_plugin 'zoxide'

    [[ $APP_DOCKER == '1' ]] && append_plugin 'docker'
    [[ $APP_DOCKER == '1' ]] && append_plugin 'docker-compose'
    [[ $APP_GIT == '1' ]] && append_plugin 'git'
    [[ $APP_TMUX == '1' ]] && append_plugin 'tmux'
    [[ $APP_VSCODE == '1' ]] && append_plugin 'vscode'

    [[ $CODE_GO == '1' ]] && append_plugin 'golang'
    [[ $CODE_PYTHON == '1' ]] && append_plugin 'python'
    [[ $CODE_PYTHON == '1' ]] && append_plugin 'uv'
    [[ $CODE_RUST == '1' ]] && append_plugin 'rust'

    append_plugin 'ohmyzsh-full-autoupdate'
    append_plugin 'you-should-use'
    append_plugin 'zsh-autosuggestions'
    append_plugin 'zsh-syntax-highlighting'

    [[ $COMMAND_MODERN_CLI == '1' ]] && append_plugin 'fzf-tab'

    return 0
}

install_theme() {
    git clone --depth=1 'https://github.com/romkatv/powerlevel10k.git' \
        "$ZSH_CUSTOM/themes/powerlevel10k"

    sed -i 's|^ZSH_THEME=".*"|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$HOME/.zshrc"
}

main() {
    if ! command -v git > /dev/null 2>&1; then
        echo 'git is not installed.' >&2
        return 1
    fi

    download_plugin
    install_plugin
    install_theme

    bash './pre_plugin.sh' "$@"
    bash './custom_env.sh' "$@"
    bash './first_run.sh' "$@"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
