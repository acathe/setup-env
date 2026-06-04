#!/usr/bin/env bash

set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-"latest"}"
LANG_BASH="${LANG_BASH:-false}"
LANG_CPP="${LANG_CPP:-false}"
LANG_GO="${LANG_GO:-false}"
LANG_PYTHON="${LANG_PYTHON:-false}"
LANG_RUST="${LANG_RUST:-false}"

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
            --lang-bash)
                LANG_BASH=true
                shift # shift once since flags have no values
                ;;
            --lang-cpp)
                LANG_CPP=true
                shift
                ;;
            --lang-go)
                LANG_GO=true
                shift
                ;;
            --lang-python)
                LANG_PYTHON=true
                shift
                ;;
            --lang-rust)
                LANG_RUST=true
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

    if $LANG_BASH; then
        image="dev-container/lang/bash"
        docker build \
            -f ./bash/Dockerfile \
            -t "$image:$IMAGE_TAG" \
            --build-arg "from=$from:$IMAGE_TAG" \
            ./bash
        from="$image"
    fi

    if false && $LANG_CPP; then
        image="dev-container/lang/cpp"
        docker build \
            -f ./cpp/Dockerfile \
            -t "$image:$IMAGE_TAG" \
            --build-arg "from=$from:$IMAGE_TAG" \
            ./cpp
        from="$image"
    fi

    if $LANG_GO; then
        image="dev-container/lang/go"
        docker build \
            -f ./go/Dockerfile \
            -t "$image:$IMAGE_TAG" \
            --build-arg "from=$from:$IMAGE_TAG" \
            ./go
        from="$image"
    fi

    if $LANG_PYTHON; then
        image="dev-container/lang/python"
        docker build \
            -f ./python/Dockerfile \
            -t "$image:$IMAGE_TAG" \
            --build-arg "from=$from:$IMAGE_TAG" \
            ./python
        from="$image"
    fi

    if $LANG_RUST; then
        image="dev-container/lang/rust"
        docker build \
            -f ./rust/Dockerfile \
            -t "$image:$IMAGE_TAG" \
            --build-arg "from=$from:$IMAGE_TAG" \
            ./rust
        from="$image"
    fi

    bash ../finish/build.sh \
        --from "$from" \
        --image "dev-container/lang" \
        --image-tag "$IMAGE_TAG" \
        "$@"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
