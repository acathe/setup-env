#!/usr/bin/env bash

set -euo pipefail

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

set_completion() {
    local completion="$1"

    local completion_dir
    completion_dir="$(brew --prefix)/share/zsh/site-functions"

    if [[ ! -f "$completion_dir/$completion" ]]; then
        echo "$completion_dir/$completion does not exist." >&2
        return 1
    fi

    mkdir -p "$ZSH_CUSTOM/completions"
    ln -sf "$completion_dir/$completion" "$ZSH_CUSTOM/completions/$completion"
}

main() {
    brew install \
        'atuin' \
        'bat' \
        'btop' \
        'eza' \
        'fd' \
        'fzf' \
        'hyperfine' \
        'micro' \
        'ripgrep' \
        'tealdeer' \
        'zoxide'

    # bat
    install -Dm 644 './bat.config' "$HOME/.config/bat/config"
    set_completion '_bat'

    # micro
    micro -plugin install detectindent
    install -Dm 644 './micro.settings.json' "$HOME/.config/micro/settings.json"

    # fd
    set_completion '_fd'

    # tldr
    set_completion '_tldr'
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
