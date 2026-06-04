#!/usr/bin/env bash

set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-"latest"}"
TOOLS_PROTOBUF="${TOOLS_PROTOBUF:-0}"
TOOLS_THRIFT="${TOOLS_THRIFT:-0}"

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
            --tools-protobuf)
                TOOLS_PROTOBUF=1
                shift # shift once since flags have no values
                ;;
            --tools-thrift)
                TOOLS_THRIFT=1
                shift # shift once since flags have no values
                ;;
            *) # unknown flag/switch
                POSITIONAL+=("${1}")
                shift
                ;;
        esac
    done
}

main() {
    from="dev-container/lang"

    if [[ $TOOLS_PROTOBUF == "1" ]]; then
        image="dev-container/tools/protobuf"
        docker build \
            -f ./protobuf.dockerfile \
            -t "$image:$IMAGE_TAG" \
            --build-arg "from=$from:$IMAGE_TAG" \
            .
        from="$image"
    fi

    if [[ $TOOLS_THRIFT == "1" ]]; then
        image="dev-container/tools/thrift"
        docker build \
            -f ./thrift.dockerfile \
            -t "$image:$IMAGE_TAG" \
            --build-arg "from=$from:$IMAGE_TAG" \
            .
        from="$image"
    fi

    bash ../finish/build.sh \
        --from "$from" \
        --image "dev-container/tools" \
        --image-tag "$IMAGE_TAG" \
        "$@"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
