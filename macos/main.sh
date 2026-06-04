#!/usr/bin/env bash

set -euo pipefail

APP_VSCODE="${APP_VSCODE:-false}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --app-vscode)
                APP_VSCODE=true
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
    if [[ ! -d "/Library/Developer/CommandLineTools" ]]; then
        xcode-select --install
    fi

    bash "./terminal/homebrew.sh" "$@"
    eval "$(/opt/homebrew/bin/brew shellenv)" # export brew PATH for child scripts

    bash "./terminal/omz/main.sh" "$@"

    if $APP_VSCODE; then
        bash "./app/vscode/main.sh" "$@"
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]+"${POSITIONAL[@]}"}" # restore positional params
    main "$@"
fi
