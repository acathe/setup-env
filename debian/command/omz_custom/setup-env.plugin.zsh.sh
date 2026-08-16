#!/usr/bin/env bash

set -euo pipefail

COMMAND_MODERN_CLI="${COMMAND_MODERN_CLI:-0}"

CODE_PYTHON="${CODE_PYTHON:-0}"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

render_blocks() {
    if [[ $COMMAND_MODERN_CLI == '1' ]]; then
        cat << 'EOF'

# eza
zstyle ":omz:plugins:eza" "dirs-first" yes
zstyle ":omz:plugins:eza" "git-status" yes
zstyle ":omz:plugins:eza" "header" yes
zstyle ":omz:plugins:eza" "icons" yes
zstyle ":omz:plugins:eza" "time-style" "relative"
EOF
    fi

    if [[ $CODE_PYTHON == '1' ]]; then
        cat << 'EOF'

# Python
PYTHON_AUTO_VRUN=true
EOF
    fi
}

main() {
    local blocks
    blocks="$(render_blocks)"

    if [[ -z $blocks ]]; then
        return 0
    fi

    mkdir -p "$ZSH_CUSTOM/plugins/setup-env"
    {
        echo '# setup-env'
        printf '%s\n' "$blocks"
    } > "$ZSH_CUSTOM/plugins/setup-env/setup-env.plugin.zsh"
    sed -i '/^plugins=(/s/(/(setup-env /' "$HOME/.zshrc"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
