#!/usr/bin/env bash

set -euo pipefail

COMMAND_MODERN_CLI="${COMMAND_MODERN_CLI:-0}"

CODE_GO="${CODE_GO:-0}"

APP_DOCKER="${APP_DOCKER:-0}"
APP_GIT="${APP_GIT:-0}"
APP_YAZI="${APP_YAZI:-0}"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

render_blocks() {
    cat << 'EOF'
# Editor
EOF

    if [[ $COMMAND_MODERN_CLI != '1' ]]; then
        cat << 'EOF'
export EDITOR=nanom
EOF
    fi

    if [[ $COMMAND_MODERN_CLI == '1' ]]; then
        cat << 'EOF'
export EDITOR=micro
EOF
    fi

    if [[ $APP_VSCODE == '1' ]]; then
        cat << 'EOF'
if [[ $TERM_PROGRAM == 'vscode' ]]; then
  export EDITOR='code --wait'
fi
EOF
    fi

    if [[ $CODE_GO == '1' ]]; then
        cat << 'EOF'

# Go
export PATH="$HOME/go/bin:$PATH"
EOF
    fi

    cat << 'EOF'

# zsh-autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# zsh-syntax-highlighting
ZSH_HIGHLIGHT_HIGHLIGHTERS+=(brackets)
ZSH_HIGHLIGHT_MAXLENGTH=512

# you-should-use
export YSU_MESSAGE_POSITION=after
EOF

    if [[ $COMMAND_MODERN_CLI != '1' ]]; then
        cat << 'EOF'

# z
ZSHZ_CASE=smart
ZSHZ_TILDE=1
EOF
    fi

    if [[ $COMMAND_MODERN_CLI == '1' ]]; then
        cat << 'EOF'

# Atuin
eval "$(atuin init zsh)"

# eza
alias tree='eza --tree'

# fzf
export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND/ --type f/}"
export FZF_ALT_C_COMMAND="${FZF_DEFAULT_COMMAND/--type f/--type d}"
export FZF_CTRL_T_OPTS='--preview "if [ -d {} ]; then eza --tree --level=2 --color=always --icons=never --group-directories-first -- {}; else bat -p --color=always -- {}; fi"'
export FZF_ALT_C_OPTS='--preview "eza --tree --level=2 --color=always --icons=never --group-directories-first -- {}"'

# fzf-tab
zstyle ":completion:*:*:*:*:*" menu no
zstyle ":completion:*:descriptions" format "[%d]"
zstyle ":completion:*" list-colors ${(s.:.)LS_COLORS}
zstyle ":completion:*:git-checkout:*" sort false
zstyle ":fzf-tab:complete:cd:*" fzf-preview 'eza -1 --color=always $realpath'
zstyle ":fzf-tab:*" switch-group "<" ">"

# Micro
export MICRO_TRUECOLOR=1
EOF
    fi

    if [[ $APP_DOCKER == '1' ]]; then
        cat << 'EOF'

# Docker
alias lzd=lazydocker
EOF
    fi

    if [[ $APP_GIT == '1' ]]; then
        cat << 'EOF'

# Git
function lg() {
    export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir
    lazygit "$@"
    if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
        cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
        rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
    fi
}
EOF
    fi

    if [[ $APP_YAZI == '1' ]]; then
        cat << 'EOF'

# yazi
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d "" cwd < "$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
    command rm -f -- "$tmp"
}
EOF
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
