#!/usr/bin/env bash

set -euo pipefail

CONTAINER="${CONTAINER:-}"
IMAGE_TAG="${IMAGE_TAG:-"latest"}"

APP_DOCKER="${APP_DOCKER:-0}"
APP_GIT="${APP_GIT:-0}"
APP_VSCODE="${APP_VSCODE:-0}"

LANG_BASH="${LANG_BASH:-0}"
LANG_GO="${LANG_GO:-0}"
LANG_PYTHON="${LANG_PYTHON:-0}"
LANG_RUST="${LANG_RUST:-0}"

TOOL_PROTOBUF="${TOOL_PROTOBUF:-0}"

GIT_USER_NAME="${GIT_USER_NAME:-}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --container)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    CONTAINER="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --image-tag)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    IMAGE_TAG="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
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
            --lang-go)
                LANG_GO=1
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
            --git-user-name)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    GIT_USER_NAME="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --git-user-email)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    GIT_USER_EMAIL="$2"
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

debian() {
    bash "./terminal/zsh.sh" "$@"
    bash "./terminal/omz/main.sh" "$@"

    if [[ $APP_DOCKER == "1" ]]; then
        bash "./app/docker.sh" "$@"
    fi

    if [[ $APP_GIT == "1" ]]; then
        bash "./app/git.sh" \
            --git-user-name "$GIT_USER_NAME" \
            --git-user-email "$GIT_USER_EMAIL"
    fi

    if [[ $APP_VSCODE == "1" ]]; then
        bash "./app/vscode.sh" "$@"
    fi

    if [[ $LANG_BASH == "1" ]]; then
        bash "./lang/bash.sh" "$@"
    fi

    if [[ $LANG_GO == "1" ]]; then
        bash "./lang/go.sh" "$@"
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

container() {
    if ! command -v docker > /dev/null 2>&1; then
        echo "Docker is not installed. Please install Docker and try again." >&2
        return 1
    fi

    if [[ -z ${USER:-} || -z ${LANG:-} ]]; then
        echo "USER or LANG is not set. Run from a normal login shell with USER and LANG exported." >&2
        return 1
    fi

    docker build \
        -t "dev-container:$IMAGE_TAG" \
        --build-arg "user=$USER" \
        --build-arg "lang=${LANG%.*}" \
        --build-arg "encoding=${LANG#*.}" \
        --build-arg "language=${LANGUAGE:-}" \
        --build-arg "tz=$(timedatectl show -p Timezone --value)" \
        --build-arg "git_user_name=$GIT_USER_NAME" \
        --build-arg "git_user_email=$GIT_USER_EMAIL" \
        .

    mkdir -p "$HOME/Projects"

    if docker container inspect "$CONTAINER" > /dev/null 2>&1; then
        echo "Container '$CONTAINER' already exists." >&2
        echo "Remove it (docker rm -f $CONTAINER) or pass --container <name>." >&2
        return 1
    fi

    docker run \
        -d \
        --privileged \
        --init \
        --restart unless-stopped \
        --shm-size=2g \
        --ulimit nofile=1048576:1048576 \
        --tmpfs /tmp:exec \
        --hostname "$CONTAINER" \
        --name "$CONTAINER" \
        -v "$HOME/Projects:/home/$USER/Projects" \
        "dev-container:$IMAGE_TAG"
}

main() {
    if [[ -n $CONTAINER ]]; then
        container
    else
        debian "$@"
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
