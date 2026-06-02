#!/usr/bin/env bash

set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-"latest"}"
USER="${USER:-}"
ENCODING="${LANG#*.}"
LANG="${LANG%.*}"
LANGUAGE="${LANGUAGE:-}"
TZ="${TZ:-"$(timedatectl show -p Timezone --value)"}"

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
            --user)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    USER="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --lang)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    LANG="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --encoding)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    ENCODING="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --language)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    LANGUAGE="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --tz)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    TZ="$2"
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
    docker build . \
        -t "dev-container/base:$IMAGE_TAG" \
        --build-arg "user=$USER" \
        --build-arg "lang=$LANG" \
        --build-arg "encoding=$ENCODING" \
        --build-arg "language=$LANGUAGE" \
        --build-arg "tz=$TZ"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
