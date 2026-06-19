#!/usr/bin/env bash

set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-"latest"}"
CONTAINER="${CONTAINER:-"dev-container"}"

USER="${USER:-}"

LANG="${LANG:-}"
LANG_CODE="${LANG%.*}"
ENCODING="${LANG#*.}"

LANGUAGE="${LANGUAGE:-}"
TZ="${TZ:-"$(timedatectl show -p Timezone --value)"}"

GIT_USER_NAME="${GIT_USER_NAME:-}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"

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
            --lang-code)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    LANG_CODE="$2"
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
            --git-user-name)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    GIT_USER_NAME="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --git-user-email)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    GIT_USER_EMAIL="$2"
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
    if ! command -v docker > /dev/null 2>&1; then
        echo "Docker is not installed. Please install Docker and try again." >&2
        return 1
    fi

    DOCKER_BUILDKIT=1 docker build \
        -t "dev-container:$IMAGE_TAG" \
        --build-arg "user=$USER" \
        --build-arg "lang_code=$LANG_CODE" \
        --build-arg "encoding=$ENCODING" \
        --build-arg "language=$LANGUAGE" \
        --build-arg "tz=$TZ" \
        --build-arg "git_user_name=$GIT_USER_NAME" \
        --build-arg "git_user_email=$GIT_USER_EMAIL" \
        .

    mkdir -p "$HOME/Projects"

    if docker container inspect "$CONTAINER" > /dev/null 2>&1; then
        echo "Container '$CONTAINER' already exists." >&2
        echo "Remove it (docker rm -f $CONTAINER) or pass --container <name>." >&2
        return 1
    fi

    docker run \
        -d \
        --privileged \
        --init \
        --restart unless-stopped \
        --shm-size=2g \
        --ulimit nofile=1048576:1048576 \
        --tmpfs /tmp:exec \
        --hostname "$CONTAINER" \
        --name "$CONTAINER" \
        -v "$HOME/Projects:/home/$USER/Projects" \
        "dev-container:$IMAGE_TAG"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
