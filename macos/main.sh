#!/usr/bin/env bash

set -euo pipefail

export COMMAND_SSH="${COMMAND_SSH:-0}"

export APP_CHATGPT="${APP_CHATGPT:-0}"
export APP_GHOSTTY="${APP_GHOSTTY:-0}"
export APP_VSCODE="${APP_VSCODE:-0}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --command-ssh)
                COMMAND_SSH=1
                shift # shift once since flags have no values
                ;;
            --app-chatgpt)
                APP_CHATGPT=1
                shift # shift once since flags have no values
                ;;
            --app-ghostty)
                APP_GHOSTTY=1
                shift # shift once since flags have no values
                ;;
            --app-vscode)
                APP_VSCODE=1
                shift # shift once since flags have no values
                ;;
            *) # unknown flag/switch
                POSITIONAL+=("$1")
                shift
                ;;
        esac
    done
}

main() {
    if [[ ! -d '/Library/Developer/CommandLineTools' ]]; then
        xcode-select --install
    fi

    bash './command/homebrew.sh' "$@"
    eval "$(/opt/homebrew/bin/brew shellenv)"

    bash './command/omz/main.sh' "$@"
    bash './command/starship.sh' "$@"

    [[ $COMMAND_SSH == '1' ]] && bash './command/ssh.sh' "$@"

    [[ $APP_CHATGPT == '1' ]] && bash './app/chatgpt.sh' "$@"
    [[ $APP_GHOSTTY == '1' ]] && bash './app/ghostty/main.sh' "$@"
    [[ $APP_VSCODE == '1' ]] && bash './app/vscode.sh' "$@"

    return 0
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]+"${POSITIONAL[@]}"}" # restore positional params
    main "$@"
fi
