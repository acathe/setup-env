#!/usr/bin/env bash

set -euo pipefail

export COMMAND_UTILS="${COMMAND_UTILS:-0}"

export CODE_BASH="${CODE_BASH:-0}"
export CODE_GO="${CODE_GO:-0}"
export CODE_PYTHON="${CODE_PYTHON:-0}"
export CODE_RUST="${CODE_RUST:-0}"

export TOOLS_PROTOBUF="${TOOLS_PROTOBUF:-0}"

export APP_CLAUDE="${APP_CLAUDE:-0}"
export APP_DOCKER="${APP_DOCKER:-0}"
export APP_GIT="${APP_GIT:-0}"
export APP_MICRO="${APP_MICRO:-0}"
export APP_TMUX="${APP_TMUX:-0}"
export APP_VSCODE="${APP_VSCODE:-0}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --command-utils)
                COMMAND_UTILS=1
                shift
                ;;
            --code-bash)
                CODE_BASH=1
                shift
                ;;
            --code-go)
                CODE_GO=1
                shift
                ;;
            --code-python)
                CODE_PYTHON=1
                shift
                ;;
            --code-rust)
                CODE_RUST=1
                shift
                ;;
            --tools-protobuf)
                TOOLS_PROTOBUF=1
                shift
                ;;
            --app-claude)
                APP_CLAUDE=1
                shift
                ;;
            --app-docker)
                APP_DOCKER=1
                shift # shift once since flags have no values
                ;;
            --app-git)
                APP_GIT=1
                shift
                ;;
            --app-micro)
                APP_MICRO=1
                shift
                ;;
            --app-tmux)
                APP_TMUX=1
                shift
                ;;
            --app-vscode)
                APP_VSCODE=1
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
    bash './command/omz.sh' "$@"
    bash './command/omz_custom/main.sh' "$@"

    if [[ $COMMAND_UTILS == '1' ]]; then
        bash './command/utils.sh' "$@"
    fi

    if [[ $CODE_BASH == '1' ]]; then
        bash './code/bash.sh' "$@"
    fi

    if [[ $CODE_GO == '1' ]]; then
        bash './code/go.sh' "$@"
    fi

    if [[ $CODE_PYTHON == '1' ]]; then
        bash './code/python.sh' "$@"
    fi

    if [[ $CODE_RUST == '1' ]]; then
        bash './code/rust.sh' "$@"
    fi

    if [[ $TOOLS_PROTOBUF == '1' ]]; then
        bash './tools/protobuf.sh' "$@"
    fi

    if [[ $APP_CLAUDE == '1' ]]; then
        bash './app/claude/main.sh' "$@"
    fi

    if [[ $APP_DOCKER == '1' ]]; then
        bash './app/docker.sh' "$@"
    fi

    if [[ $APP_GIT == '1' ]]; then
        bash './app/git/main.sh' "$@"
    fi

    if [[ $APP_MICRO == '1' ]]; then
        bash './app/micro/main.sh' "$@"
    fi

    if [[ $APP_TMUX == '1' ]]; then
        bash './app/tmux.sh' "$@"
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
