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
    if [[ $TERM_PROGRAM != 'ghostty' ]]; then
        echo 'Run from a Ghostty SSH login shell with TERM_PROGRAM exported.' >&2
        return 1
    fi

    if [[ -z $USER || -z $LANG || -z $TERM || -z $COLORTERM || -z $TERM_PROGRAM_VERSION ]]; then
        echo 'USER, LANG, TERM, COLORTERM, or TERM_PROGRAM_VERSION is not set.' >&2
        return 1
    fi

    if ! command -v docker > /dev/null 2>&1 || ! command -v infocmp > /dev/null 2>&1; then
        echo 'docker or infocmp is not installed.' >&2
        return 1
    fi

    if docker container inspect "$CONTAINER" > /dev/null 2>&1; then
        echo "Container '$CONTAINER' already exists." >&2
        echo "Remove it (docker rm -f $CONTAINER) or pass --container <name>." >&2
        return 1
    fi

    local setup_args_b64
    setup_args_b64="$(for arg; do printf '%s\0' "$arg"; done | base64 | tr -d '\n')"

    local terminfo_b64
    terminfo_b64="$(infocmp -x "$TERM" | base64 | tr -d '\n')"
    if [[ -z $terminfo_b64 ]]; then
        echo "Failed to export terminfo for '$TERM'." >&2
        return 1
    fi

    docker build \
        -q \
        --tag "dev-container:$IMAGE_TAG" \
        --file './Dockerfile' \
        --build-arg "user=$USER" \
        --build-arg "lang=${LANG%.*}" \
        --build-arg "encoding=${LANG#*.}" \
        --build-arg "language=${LANGUAGE:-}" \
        --build-arg "tz=$(timedatectl show -p Timezone --value)" \
        --build-arg "term=$TERM" \
        --build-arg "colorterm=$COLORTERM" \
        --build-arg "term_program=$TERM_PROGRAM" \
        --build-arg "term_program_version=$TERM_PROGRAM_VERSION" \
        --build-arg "terminfo_b64=$terminfo_b64" \
        --build-arg "setup_args_b64=$setup_args_b64" \
        '../../debian'

    mkdir -p "$HOME/Projects"

    docker run \
        -q \
        --detach \
        --privileged \
        --init \
        --restart unless-stopped \
        --shm-size=2g \
        --ulimit nofile=1048576:1048576 \
        --tmpfs /tmp:exec \
        --hostname "$CONTAINER" \
        --name "$CONTAINER" \
        --volume "$HOME/Projects:/home/$USER/Projects" \
        "dev-container:$IMAGE_TAG"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
