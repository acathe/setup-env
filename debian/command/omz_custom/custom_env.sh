#!/usr/bin/env bash

set -euo pipefail

COMMAND_UTILS="${COMMAND_UTILS:-0}"

APP_DOCKER="${APP_DOCKER:-0}"
APP_GIT="${APP_GIT:-0}"
APP_TMUX="${APP_TMUX:-0}"
APP_VSCODE="${APP_VSCODE:-0}"

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

    if [[ $COMMAND_UTILS == '1' ]]; then
        echo
        echo '# Command utilities'
        echo 'alias fd="fdfind"'
        echo 'alias tree="eza --tree"'
        echo
        echo '# bat'
        echo 'compdef bat=batcat'
        echo
        echo '# Editor'
        echo 'export EDITOR=micro'
        if [[ $APP_VSCODE == '1' ]]; then
            echo 'if [[ "$TERM_PROGRAM" == "vscode" ]]; then'
            echo '  export EDITOR="code --wait"'
            echo 'fi'
        fi
        echo 'export VISUAL="$EDITOR"'
        echo
        echo '# Micro'
        echo 'export MICRO_TRUECOLOR=1'
        echo 'alias micror="micro -readonly true"'
        echo
        echo '# yazi'
        echo 'function y() {'
        echo '    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd'
        echo '    command yazi "$@" --cwd-file="$tmp"'
        echo '    IFS= read -r -d "" cwd < "$tmp"'
        echo '    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"'
        echo '    command rm -f -- "$tmp"'
        echo '}'
    fi

    if [[ $APP_DOCKER == '1' ]]; then
        echo
        echo '# Docker'
        echo 'alias lzd="lazydocker"'
    fi

    if [[ $APP_GIT == '1' ]]; then
        echo
        echo '# Git'
        echo 'function lg() {'
        echo '    export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir'
        echo '    lazygit "$@"'
        echo '    if [ -f $LAZYGIT_NEW_DIR_FILE ]; then'
        echo '        cd "$(cat $LAZYGIT_NEW_DIR_FILE)"'
        echo '        rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null'
        echo '    fi'
        echo '}'
    fi

    if [[ $APP_TMUX == '1' ]]; then
        echo
        echo '# tmux mouse scroll'
        echo 'export LESS="-R -F --mouse"'
    fi
}

main() {
    mkdir -p "$ZSH_CUSTOM"
    render_blocks > "$ZSH_CUSTOM/00-setup_env.zsh"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
