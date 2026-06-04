#!/usr/bin/env bash

set -euo pipefail

APP_DOCKER="${APP_DOCKER:-0}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --app-docker)
                APP_DOCKER=1
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
    bash "./terminal/zsh.sh" "$@"
    bash "./terminal/omz.sh" "$@"

    if [[ $APP_DOCKER == "1" ]]; then
        bash "./app/docker.sh" "$@"
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
