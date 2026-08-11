#!/usr/bin/env bash

set -euo pipefail

CONTAINER="${CONTAINER:-dev-container}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

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
            *) # unknown flag/switch
                POSITIONAL+=("$1")
                shift
                ;;
        esac
    done
}

main() {
    if ! command -v docker > /dev/null 2>&1; then
        echo 'Docker is not installed.' >&2
        return 1
    fi

    if [[ -z $USER || -z $LANG ]]; then
        echo 'USER or LANG is not set. Run from a normal login shell with USER and LANG exported.' >&2
        return 1
    fi

    if docker container inspect "$CONTAINER" > /dev/null 2>&1; then
        echo "Container '$CONTAINER' already exists." >&2
        echo "Remove it (docker rm -f $CONTAINER) or pass --container <name>." >&2
        return 1
    fi

    local setup_args_b64
    setup_args_b64="$(for arg; do printf '%s\0' "$arg"; done | base64 | tr -d '\n')"

    docker build \
        -t "dev-container:$IMAGE_TAG" \
        -f './Dockerfile' \
        --build-arg "user=$USER" \
        --build-arg "lang=${LANG%.*}" \
        --build-arg "encoding=${LANG#*.}" \
        --build-arg "language=${LANGUAGE:-}" \
        --build-arg "tz=$(timedatectl show -p Timezone --value)" \
        --build-arg "setup_args_b64=$setup_args_b64" \
        '../../debian'

    mkdir -p "$HOME/Projects"

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

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
