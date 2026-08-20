#!/usr/bin/env bash

set -euo pipefail

UNATTENDED="${UNATTENDED:-0}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --unattended)
                UNATTENDED=1
                shift
                ;;
            *) # unknown flag/switch
                POSITIONAL+=("$1")
                shift
                ;;
        esac
    done
}

main() {
    if command -v brew > /dev/null 2>&1; then
        echo 'Homebrew is already installed.'
        return 0
    fi

    if ! command -v curl > /dev/null 2>&1; then
        echo 'curl is not installed.' >&2
        return 1
    fi

    # Ref. https://brew.sh/zh-cn/
    if [[ $UNATTENDED == '1' ]]; then
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL 'https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh')"
    else
        /bin/bash -c "$(curl -fsSL 'https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh')"
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
