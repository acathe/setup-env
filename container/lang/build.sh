#!/usr/bin/env bash

set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-"latest"}"
LANG_BASH="${LANG_BASH:-0}"
LANG_GO="${LANG_GO:-0}"
LANG_PYTHON="${LANG_PYTHON:-0}"
LANG_RUST="${LANG_RUST:-0}"

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
                LANG_BASH=1
                shift # shift once since flags have no values
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
            *) # unknown flag/switch
                POSITIONAL+=("${1}")
                shift
                ;;
        esac
    done
}

main() {
    from="dev-container/terminal"

    if [[ $LANG_BASH == "1" ]]; then
        image="dev-container/lang/bash"
        docker build \
            -f ./bash.dockerfile \
            -t "$image:$IMAGE_TAG" \
            --build-arg "from=$from:$IMAGE_TAG" \
            .
        from="$image"
    fi

    if [[ $LANG_GO == "1" ]]; then
        image="dev-container/lang/go"
        docker build \
            -f ./go.dockerfile \
            -t "$image:$IMAGE_TAG" \
            --build-arg "from=$from:$IMAGE_TAG" \
            .
        from="$image"
    fi

    if [[ $LANG_PYTHON == "1" ]]; then
        image="dev-container/lang/python"
        docker build \
            -f ./python.dockerfile \
            -t "$image:$IMAGE_TAG" \
            --build-arg "from=$from:$IMAGE_TAG" \
            .
        from="$image"
    fi

    if [[ $LANG_RUST == "1" ]]; then
        image="dev-container/lang/rust"
        docker build \
            -f ./rust.dockerfile \
            -t "$image:$IMAGE_TAG" \
            --build-arg "from=$from:$IMAGE_TAG" \
            .
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
