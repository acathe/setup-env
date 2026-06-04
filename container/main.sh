#!/usr/bin/env bash

set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-"latest"}"
CONTAINER="${CONTAINER:-"dev-container"}"
USER="${USER:-}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --image-tag)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    IMAGE_TAG="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --container)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    CONTAINER="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;

            --user)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    USER="$2"
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
    bash "./base/build.sh" --image-tag "$IMAGE_TAG" --user "$USER" "$@"
    bash "./terminal/build.sh" --image-tag "$IMAGE_TAG" --user "$USER" "$@"
    bash "./lang/build.sh" --image-tag "$IMAGE_TAG" "$@"
    bash "./tools/build.sh" --image-tag "$IMAGE_TAG" "$@"

    bash ./finish/build.sh \
        --from "dev-container/tools" \
        --image "dev-container/main" \
        --image-tag "$IMAGE_TAG" \
        "$@"

    [[ ! -d "$HOME/Projects" ]] && mkdir -p "$HOME/Projects"

    docker run \
        -d \
        --privileged \
        --init \
        --shm-size=2g \
        --name "$CONTAINER" \
        -v "$HOME/Projects:/home/$USER/Projects" \
        "dev-container/main:$IMAGE_TAG"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
