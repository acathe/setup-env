#!/usr/bin/env bash

set -euo pipefail

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
    from="dev-container/terminal"

    if $DEV_BASH && [[ -f "./bash/build.sh" ]]; then
        image="dev-container/dev/bash"
        docker build ./bash \
            -f ./bash/Dockerfile \
            -t "$image:$IMAGE_TAG" \
            --build-arg "from=$from:$IMAGE_TAG"
        from="$image"
    fi

    if false && $DEV_CPP && [[ -f "./cpp/build.sh" ]]; then
        image="dev-container/dev/cpp"
        docker build ./cpp \
            -f ./cpp/Dockerfile \
            -t "$image:$IMAGE_TAG" \
            --build-arg "from=$from:$IMAGE_TAG"
        from="$image"
    fi

    if $DEV_GO && [[ -f "./go/build.sh" ]]; then
        image="dev-container/dev/go"
        docker build ./go \
            -f ./go/Dockerfile \
            -t "$image:$IMAGE_TAG" \
            --build-arg "from=$from:$IMAGE_TAG"
        from="$image"
    fi

    if $DEV_PYTHON && [[ -f "./python/build.sh" ]]; then
        image="dev-container/dev/python"
        docker build ./python \
            -f ./python/Dockerfile \
            -t "$image:$IMAGE_TAG" \
            --build-arg "from=$from:$IMAGE_TAG"
        from="$image"
    fi

    if $DEV_RUST && [[ -f "./rust/build.sh" ]]; then
        image="dev-container/dev/rust"
        docker build ./rust \
            -f ./rust/Dockerfile \
            -t "$image:$IMAGE_TAG" \
            --build-arg "from=$from:$IMAGE_TAG"
        from="$image"
    fi

    docker build . \
        -t "dev-container/dev:$IMAGE_TAG" \
        --build-arg "from=$from:$IMAGE_TAG"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
