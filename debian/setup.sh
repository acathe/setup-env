#!/usr/bin/env bash

set -euo pipefail

APP_DOCKER="${APP_DOCKER:-0}"
APP_GIT="${APP_GIT:-0}"
APP_VSCODE="${APP_VSCODE:-0}"

LANG_BASH="${LANG_BASH:-0}"
LANG_CSHARP="${LANG_CSHARP:-0}"
LANG_GO="${LANG_GO:-0}"
LANG_POWERSHELL="${LANG_POWERSHELL:-0}"
LANG_PYTHON="${LANG_PYTHON:-0}"
LANG_RUST="${LANG_RUST:-0}"

TOOL_PROTOBUF="${TOOL_PROTOBUF:-0}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --app-docker)
                APP_DOCKER=1
                shift # shift once since flags have no values
                ;;
            --app-git)
                APP_GIT=1
                shift
                ;;
            --app-vscode)
                APP_VSCODE=1
                shift
                ;;
            --lang-bash)
                LANG_BASH=1
                shift
                ;;
            --lang-csharp)
                LANG_CSHARP=1
                shift
                ;;
            --lang-go)
                LANG_GO=1
                shift
                ;;
            --lang-powershell)
                LANG_POWERSHELL=1
                shift
                ;;
            --lang-python)
                LANG_PYTHON=1
                shift
                ;;
            --lang-rust)
                LANG_RUST=1
                shift
                ;;
            --tool-protobuf)
                TOOL_PROTOBUF=1
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
    bash "./terminal/zsh.sh" "$@"
    bash "./terminal/omz.sh" "$@"

    if [[ $APP_DOCKER == "1" ]]; then
        bash "./app/docker.sh" "$@"
    fi

    if [[ $APP_GIT == "1" ]]; then
        bash "./app/git.sh" "$@"
    fi

    if [[ $APP_VSCODE == "1" ]]; then
        bash "./app/vscode.sh" "$@"
    fi

    if [[ $LANG_BASH == "1" ]]; then
        bash "./lang/bash.sh" "$@"
    fi

    if [[ $LANG_CSHARP == "1" ]]; then
        bash "./lang/csharp.sh" "$@"
    fi

    if [[ $LANG_GO == "1" ]]; then
        bash "./lang/go.sh" "$@"
    fi

    if [[ $LANG_POWERSHELL == "1" ]]; then
        bash "./lang/powershell.sh" "$@"
    fi

    if [[ $LANG_PYTHON == "1" ]]; then
        bash "./lang/python.sh" "$@"
    fi

    if [[ $LANG_RUST == "1" ]]; then
        bash "./lang/rust.sh" "$@"
    fi

    if [[ $TOOL_PROTOBUF == "1" ]]; then
        bash "./tool/protobuf.sh" "$@"
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
