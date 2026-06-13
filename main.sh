#!/usr/bin/env bash

set -euo pipefail

BRANCH="${BRANCH:-"master"}"
SETUP="${SETUP:-"container"}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --branch)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    BRANCH="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --setup)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    SETUP="$2"
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

macos() {
    if [[ ! -d "/Library/Developer/CommandLineTools" ]]; then
        xcode-select --install
    fi
}

debian() {
    if [[ -z "$(command -v git)" ]]; then
        sudo apt-get update
        sudo apt-get install -y git
    fi
}

vscode() {
    if [[ -z "$(command -v code)" ]]; then
        echo "VS Code CLI 'code' not found in PATH." >&2
        return 1
    fi
}

main() {
    case "$SETUP" in
        macos)
            macos
            ;;
        debian | container)
            debian
            ;;
        vscode)
            vscode
            ;;
        *)
            echo "Unsupported setup: $SETUP" >&2
            return 1
            ;;
    esac

    tmpdir="$(mktemp -du "/tmp/setup_env.XXXXXX")"

    git clone "https://github.com/acathe/setup-env.git" "$tmpdir" \
        --depth 1 \
        --single-branch \
        --branch "$BRANCH"

    bash "$tmpdir/$SETUP/main.sh" "$@"
}

# Entry point
parse_args "$@"
set -- "${POSITIONAL[@]+"${POSITIONAL[@]}"}" # restore positional params
main "$@"
