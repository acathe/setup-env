#!/usr/bin/env bash

set -euo pipefail

APP_GIT="${APP_GIT:-0}"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

render_blocks() {
    if [[ $APP_GIT == '1' ]]; then
        echo '# GitHub CLI'
        echo 'if command -v gh > /dev/null 2>&1 && ! gh auth status > /dev/null 2>&1; then'
        echo '    gh auth login'
        echo 'fi'
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
        echo '[[ ${SETUP_ENV_FIRST_RUN:-1} == 0 ]] && return'
        echo
        echo '{'
        echo '    echo'
        echo '    echo "# first run"'
        echo '    echo "SETUP_ENV_FIRST_RUN=0"'
        echo '} >> "$ZSH_CUSTOM/00-setup_env.zsh"'
        echo
        echo "$blocks"
    } > "$ZSH_CUSTOM/01-first_run.zsh"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
