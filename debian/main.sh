#!/usr/bin/env bash

set -euo pipefail

export COMMAND_MODERN_CLI="${COMMAND_MODERN_CLI:-0}"

export CODE_BASH="${CODE_BASH:-0}"
export CODE_GO="${CODE_GO:-0}"
export CODE_MARKDOWN="${CODE_MARKDOWN:-0}"
export CODE_PROTOBUF="${CODE_PROTOBUF:-0}"
export CODE_PYTHON="${CODE_PYTHON:-0}"
export CODE_RUST="${CODE_RUST:-0}"

export APP_CLAUDE="${APP_CLAUDE:-0}"
export APP_DOCKER="${APP_DOCKER:-0}"
export APP_GIT="${APP_GIT:-0}"
export APP_NEOVIM="${APP_NEOVIM:-0}"
export APP_TMUX="${APP_TMUX:-0}"
export APP_VSCODE="${APP_VSCODE:-0}"
export APP_YAZI="${APP_YAZI:-0}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --command-modern-cli)
                COMMAND_MODERN_CLI=1
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
            --code-markdown)
                CODE_MARKDOWN=1
                shift
                ;;
            --code-protobuf)
                CODE_PROTOBUF=1
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
            --app-neovim)
                APP_NEOVIM=1
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
            --app-yazi)
                APP_YAZI=1
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
    bash './command/omz/main.sh' "$@"
    bash './command/omz_custom/main.sh' "$@"
    bash './command/classic_cli/main.sh' "$@"

    if [[ $COMMAND_MODERN_CLI == '1' ]]; then
        bash './command/modern_cli/main.sh' "$@"
    fi

    if [[ $CODE_BASH == '1' ]]; then
        bash './code/bash.sh' "$@"
    fi

    if [[ $CODE_GO == '1' ]]; then
        bash './code/go.sh' "$@"
    fi

    if [[ $CODE_MARKDOWN == '1' ]]; then
        bash './code/markdown/main.sh' "$@"
    fi

    if [[ $CODE_PROTOBUF == '1' ]]; then
        bash './code/protobuf.sh' "$@"
    fi

    if [[ $CODE_PYTHON == '1' ]]; then
        bash './code/python.sh' "$@"
    fi

    if [[ $CODE_RUST == '1' ]]; then
        bash './code/rust.sh' "$@"
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

    if [[ $APP_NEOVIM == '1' ]]; then
        bash './app/neovim.sh' "$@"
    fi

    if [[ $APP_TMUX == '1' ]]; then
        bash './app/tmux.sh' "$@"
    fi

    if [[ $APP_YAZI == '1' ]]; then
        bash './app/yazi/main.sh' "$@"
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
