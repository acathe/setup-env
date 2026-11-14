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
    if [[ "$IMAGE" == "copilot-api" ]]; then
        bash "./$IMAGE/main.sh" "$@"
    else
        printf 'Unsupported image: %s\n' "${IMAGE:-<empty>}" >&2
        return 1
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}"
    main "$@"
fi
