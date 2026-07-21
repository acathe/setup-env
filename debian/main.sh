#!/usr/bin/env bash

set -euo pipefail

export AGENT_CLAUDE="${AGENT_CLAUDE:-0}"

export APP_DOCKER="${APP_DOCKER:-0}"
export APP_GIT="${APP_GIT:-0}"
export APP_GITHUB="${APP_GITHUB:-0}"
export APP_MICRO="${APP_MICRO:-0}"
export APP_TMUX="${APP_TMUX:-0}"
export APP_VSCODE="${APP_VSCODE:-0}"

export CODE_BASH="${CODE_BASH:-0}"
export CODE_CSHARP="${CODE_CSHARP:-0}"
export CODE_GO="${CODE_GO:-0}"
export CODE_POWERSHELL="${CODE_POWERSHELL:-0}"
export CODE_PYTHON="${CODE_PYTHON:-0}"
export CODE_RUST="${CODE_RUST:-0}"

export TOOLS_NODE="${TOOLS_NODE:-0}"
export TOOLS_PROTOBUF="${TOOLS_PROTOBUF:-0}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --agent-claude)
                AGENT_CLAUDE=1
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
            --app-github)
                APP_GITHUB=1
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
            --code-bash)
                CODE_BASH=1
                shift
                ;;
            --code-csharp)
                CODE_CSHARP=1
                shift
                ;;
            --code-go)
                CODE_GO=1
                shift
                ;;
            --code-powershell)
                CODE_POWERSHELL=1
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
            --tools-node)
                TOOLS_NODE=1
                shift
                ;;
            --tools-protobuf)
                TOOLS_PROTOBUF=1
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
    bash "./command/zsh.sh" "$@"
    bash "./command/omz.sh" "$@"

    if [[ $AGENT_CLAUDE == "1" ]]; then
        bash "./agent/claude/main.sh" "$@"
    fi

    if [[ $APP_DOCKER == "1" ]]; then
        bash "./app/docker.sh" "$@"
    fi

    if [[ $APP_GIT == "1" ]]; then
        bash "./app/git.sh" "$@"
    fi

    if [[ $APP_GITHUB == "1" ]]; then
        bash "./app/github.sh" "$@"
    fi

    if [[ $APP_MICRO == "1" ]]; then
        bash "./app/micro.sh" "$@"
    fi

    if [[ $APP_TMUX == "1" ]]; then
        bash "./app/tmux.sh" "$@"
    fi

    if [[ $APP_VSCODE == "1" ]]; then
        bash "./app/vscode.sh" "$@"
    fi

    if [[ $CODE_BASH == "1" ]]; then
        bash "./code/bash.sh" "$@"
    fi

    if [[ $CODE_CSHARP == "1" ]]; then
        bash "./code/csharp.sh" "$@"
    fi

    if [[ $CODE_GO == "1" ]]; then
        bash "./code/go.sh" "$@"
    fi

    if [[ $CODE_POWERSHELL == "1" ]]; then
        bash "./code/powershell.sh" "$@"
    fi

    if [[ $CODE_PYTHON == "1" ]]; then
        bash "./code/python.sh" "$@"
    fi

    if [[ $CODE_RUST == "1" ]]; then
        bash "./code/rust.sh" "$@"
    fi

    if [[ $TOOLS_NODE == "1" ]]; then
        bash "./tools/node.sh" "$@"
    fi

    if [[ $TOOLS_PROTOBUF == "1" ]]; then
        bash "./tools/protobuf.sh" "$@"
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
