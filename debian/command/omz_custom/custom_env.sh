#!/usr/bin/env bash

set -euo pipefail

COMMAND_MODERN_CLI="${COMMAND_MODERN_CLI:-0}"

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

    if [[ $COMMAND_MODERN_CLI != '1' ]]; then
        echo
        echo '# z'
        echo 'ZSHZ_CASE=smart'
        echo 'ZSHZ_TILDE=1'
    fi

    if [[ $COMMAND_MODERN_CLI == '1' ]]; then
        echo
        echo '# eza'
        echo 'alias tree="eza --tree"'
        echo
        echo '# bat'
        echo 'compdef bat=batcat'
        echo
        echo '# fzf'
        echo 'export FZF_CTRL_T_OPTS="--preview \"bat --color=always --style=numbers --line-range=:200 -- {}\" --preview-window=right,60%,wrap --bind \"ctrl-/:change-preview-window(down|hidden|)\""'
        echo 'export FZF_ALT_C_OPTS="--preview \"eza --tree --level=2 --color=always --icons=never -- {}\" --preview-window=right,60%,wrap --bind \"ctrl-/:change-preview-window(down|hidden|)\""'
        echo
        echo '# fzf-tab'
        echo 'zstyle ":completion:*:*:*:*:*" menu no'
        echo 'zstyle ":completion:*:descriptions" format "[%d]"'
        echo 'zstyle ":completion:*" list-colors ${(s.:.)LS_COLORS}'
        echo 'zstyle ":completion:*:git-checkout:*" sort false'
        echo 'zstyle ":fzf-tab:*" switch-group "<" ">"'
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
