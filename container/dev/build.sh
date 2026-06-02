#!/usr/bin/env bash

set -euo pipefail

FROM="${FROM:-"dev-container/terminal"}"
IMAGE_TAG="${IMAGE_TAG:-"latest"}"
DEV_BASH="${DEV_BASH:-false}"
DEV_CPP="${DEV_CPP:-false}"
DEV_GO="${DEV_GO:-false}"
DEV_PYTHON="${DEV_PYTHON:-false}"
DEV_RUST="${DEV_RUST:-false}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --from)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    FROM="$2"
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
            --dev-bash)
                DEV_BASH=true
                shift # shift once since flags have no values
                ;;
            --dev-cpp)
                DEV_CPP=true
                shift
                ;;
            --dev-go)
                DEV_GO=true
                shift
                ;;
            --dev-python)
                DEV_PYTHON=true
                shift
                ;;
            --dev-rust)
                DEV_RUST=true
                shift
                ;;
            *) # unknown flag/switch
                POSITIONAL+=("${1}")
                shift
                ;;
        esac
    done
}

main() {
    if $DEV_BASH && [[ -f "./bash/build.sh" ]]; then
        bash ./bash/build.sh --from "$FROM" --image-tag "$IMAGE_TAG" "$@"
        FROM="dev-container/dev/bash"
    fi

    if false && $DEV_CPP && [[ -f "./cpp/build.sh" ]]; then
        bash ./cpp/build.sh --from "$FROM" --image-tag "$IMAGE_TAG" "$@"
        FROM="dev-container/dev/cpp"
    fi

    if $DEV_GO && [[ -f "./go/build.sh" ]]; then
        bash ./go/build.sh --from "$FROM" --image-tag "$IMAGE_TAG" "$@"
        FROM="dev-container/dev/go"
    fi

    if $DEV_PYTHON && [[ -f "./python/build.sh" ]]; then
        bash ./python/build.sh --from "$FROM" --image-tag "$IMAGE_TAG" "$@"
        FROM="dev-container/dev/python"
    fi

    if $DEV_RUST && [[ -f "./rust/build.sh" ]]; then
        bash ./rust/build.sh --from "$FROM" --image-tag "$IMAGE_TAG" "$@"
        FROM="dev-container/dev/rust"
    fi

    docker build . \
        -t "dev-container/dev:$IMAGE_TAG" \
        --build-arg "from=$FROM:$IMAGE_TAG"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
