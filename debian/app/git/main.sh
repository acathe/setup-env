#!/usr/bin/env bash

set -euo pipefail

APP_GIT_USER_NAME="${APP_GIT_USER_NAME:-}"
APP_GIT_USER_EMAIL="${APP_GIT_USER_EMAIL:-}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --app-git-user-name)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    APP_GIT_USER_NAME="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --app-git-user-email)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    APP_GIT_USER_EMAIL="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            *) # unknown flag/switch
                POSITIONAL+=("$1")
                shift
                ;;
        esac
    done
}

add_repo() {
    # Ref. https://github.com/cli/cli/blob/trunk/docs/install_linux.md
    (type -p wget > /dev/null || (sudo apt-get update && sudo apt-get install wget -y)) \
        && sudo mkdir -p -m 755 '/etc/apt/keyrings' \
        && out=$(mktemp) && wget -nv "-O$out" 'https://cli.github.com/packages/githubcli-archive-keyring.gpg' \
        && sudo cp "$out" '/etc/apt/keyrings/githubcli-archive-keyring.gpg' \
        && sudo chmod go+r '/etc/apt/keyrings/githubcli-archive-keyring.gpg' \
        && sudo mkdir -p -m 755 '/etc/apt/sources.list.d' \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee '/etc/apt/sources.list.d/github-cli.list' > /dev/null
}

install_tools() {
    sudo apt-get update
    sudo apt-get install -y \
        gh \
        git-delta \
        lazygit
}

setup_git() {
    if [[ -n $APP_GIT_USER_NAME ]]; then
        git config --global user.name "$APP_GIT_USER_NAME"
    fi

    if [[ -n $APP_GIT_USER_EMAIL ]]; then
        git config --global user.email "$APP_GIT_USER_EMAIL"
    fi

    git config --global core.pager delta
    git config --global interactive.diffFilter 'delta --color-only'
    git config --global delta.navigate true
    git config --global delta.line-numbers true
    git config --global delta.side-by-side true
    git config --global delta.syntax-theme TwoDark
    git config --global merge.conflictStyle zdiff3

    install -Dm 644 './config.yml' "$HOME/.config/lazygit/config.yml"
}

main() {
    if ! command -v git > /dev/null 2>&1; then
        echo 'git is not installed.' >&2
        return 1
    fi

    add_repo
    install_tools
    setup_git
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
