#!/usr/bin/env bash

set -euo pipefail

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

set_completion() {
    local completion
    local completion_dir
    local -a completions=('_bat' '_fd' '_tldr')

    completion_dir="$(brew --prefix)/share/zsh/site-functions"
    for completion in "${completions[@]}"; do
        if [[ ! -f "$completion_dir/$completion" ]]; then
            echo "$completion_dir/$completion does not exist." >&2
            return 1
        fi
    done

    mkdir -p "$ZSH_CUSTOM/completions"
    for completion in "${completions[@]}"; do
        ln -sf "$completion_dir/$completion" "$ZSH_CUSTOM/completions/$completion"
    done
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

    set_completion
    bash './bat/main.sh' "$@"
    bash './micro/main.sh' "$@"
    tldr --update || true # 预热 tealdeer 离线缓存，网络失败不致命
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
