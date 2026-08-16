#!/usr/bin/env bash

set -euo pipefail

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

render_blocks() {
    echo '# zsh-autosuggestions'
    echo 'ZSH_AUTOSUGGEST_STRATEGY=(history completion)'
    echo 'ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20'
    echo
    echo '# zsh-syntax-highlighting'
    echo 'ZSH_HIGHLIGHT_HIGHLIGHTERS+=(brackets)'
    echo 'ZSH_HIGHLIGHT_MAXLENGTH=512'
    echo
    echo '# you-should-use'
    echo 'export YSU_MESSAGE_POSITION="after"'
    echo
    echo '# z'
    echo 'ZSHZ_CASE=smart'
    echo 'ZSHZ_TILDE=1'
}

main() {
    mkdir -p "$ZSH_CUSTOM"
    render_blocks > "$ZSH_CUSTOM/00-setup_env.zsh"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
