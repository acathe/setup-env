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
    bash './command/homebrew.sh' "$@"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"

    bash './command/omz/main.sh' "$@"
    bash './command/starship.sh' "$@"
    bash './command/classic_cli/main.sh' "$@"
    bash './command/ssh/main.sh' "$@"

    [[ $COMMAND_MODERN_CLI == '1' ]] && bash './command/modern_cli/main.sh' "$@"

    [[ $CODE_BASH == '1' ]] && bash './code/bash.sh' "$@"
    [[ $CODE_GO == '1' ]] && bash './code/go.sh' "$@"
    [[ $CODE_MARKDOWN == '1' ]] && bash './code/markdown/main.sh' "$@"
    [[ $CODE_PROTOBUF == '1' ]] && bash './code/protobuf.sh' "$@"
    [[ $CODE_PYTHON == '1' ]] && bash './code/python.sh' "$@"
    [[ $CODE_RUST == '1' ]] && bash './code/rust.sh' "$@"

    [[ $APP_CLAUDE == '1' ]] && bash './app/claude/main.sh' "$@"
    [[ $APP_DOCKER == '1' ]] && bash './app/docker.sh' "$@"
    [[ $APP_GIT == '1' ]] && bash './app/git/main.sh' "$@"
    [[ $APP_NEOVIM == '1' ]] && bash './app/neovim.sh' "$@"
    [[ $APP_TMUX == '1' ]] && bash './app/tmux/main.sh' "$@"
    [[ $APP_YAZI == '1' ]] && bash './app/yazi/main.sh' "$@"

    return 0
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
