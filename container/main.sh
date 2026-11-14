#!/usr/bin/env bash

set -euo pipefail

IMAGE="${IMAGE:-}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --image)
                numOfArgs=1
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    IMAGE="$2"
                    shift $((numOfArgs + 1))
                fi
                ;;
            *)
                POSITIONAL+=("$1")
                shift
                ;;
        esac
    done
}

main() {
    if [[ -z "$IMAGE" || "$IMAGE" == "." || "$IMAGE" == ".." || "$IMAGE" == */* || ! -f "./$IMAGE/main.sh" ]]; then
        printf 'Unsupported image: %s (expected a container subdirectory with main.sh)\n' "${IMAGE:-<empty>}" >&2
        return 1
    fi
    bash "./$IMAGE/main.sh" "$@"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}"
    main "$@"
fi
