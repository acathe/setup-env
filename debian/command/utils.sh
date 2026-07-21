#!/usr/bin/env bash

set -euo pipefail

COMMAND_UTILS_GIT_USER_NAME="${COMMAND_UTILS_GIT_USER_NAME:-}"
COMMAND_UTILS_GIT_USER_EMAIL="${COMMAND_UTILS_GIT_USER_EMAIL:-}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --command-utils-git-user-name)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    COMMAND_UTILS_GIT_USER_NAME="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --command-utils-git-user-email)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    COMMAND_UTILS_GIT_USER_EMAIL="$2"
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

setup_git() {
    if [[ -n $COMMAND_UTILS_GIT_USER_NAME ]]; then
        git config --global user.name "$COMMAND_UTILS_GIT_USER_NAME"
    fi
    if [[ -n $COMMAND_UTILS_GIT_USER_EMAIL ]]; then
        git config --global user.email "$COMMAND_UTILS_GIT_USER_EMAIL"
    fi

    sed -i '/^plugins=(/s/)/ git)/' "$HOME/.zshrc"
}

main() {
    sudo apt-get update
    sudo apt-get install -y \
        tree \
        jq \
        unzip \
        glow

    setup_git
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
