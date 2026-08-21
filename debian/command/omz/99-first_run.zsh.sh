#!/usr/bin/env bash

set -euo pipefail

APP_GIT="${APP_GIT:-0}"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

render_blocks() {
    if [[ $APP_GIT == '1' ]]; then
        cat << 'EOF'

# GitHub CLI
if command -v gh > /dev/null 2>&1 && ! gh auth status > /dev/null 2>&1; then
    gh auth login
fi
EOF
    fi
}

main() {
    local blocks
    blocks="$(render_blocks)"

    if [[ -z $blocks ]]; then
        return 0
    fi

    mkdir -p "$ZSH_CUSTOM"

    {
        printf '%s\n' 'command rm -f -- "${(%):-%x}"'
        printf '%s\n' "$blocks"
    } > "$ZSH_CUSTOM/99-first_run.zsh"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
