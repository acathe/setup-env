#!/usr/bin/env bash

set -euo pipefail

FROM="${FROM:-"dev-container/terminal"}"
IMAGE_TAG="${IMAGE_TAG:-"latest"}"

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
            *) # unknown flag/switch
                POSITIONAL+=("${1}")
                shift
                ;;
        esac
    done
}

main() {
    docker build . \
        -t "dev-container/tools/protobuf:$IMAGE_TAG" \
        --build-arg "from=$FROM:$IMAGE_TAG"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
