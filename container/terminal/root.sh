#!/usr/bin/env bash

set -euo pipefail

SETUP_USER="${SETUP_USER:-}"
LANG_CODE="${LANG_CODE:-}"
ENCODING="${ENCODING:-}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --user)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    SETUP_USER="$2"
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
            *) # unknown flag/switch
                POSITIONAL+=("$1")
                shift
                ;;
        esac
    done
}

install_locale() {
    apt-get update
    apt-get install -y locales
    rm -rf /var/lib/apt/lists/*
    localedef -i "${LANG_CODE}" -c -f "${ENCODING}" -A /usr/share/locale/locale.alias "${LANG_CODE}.${ENCODING}"
}

create_user() {
    apt-get update
    apt-get install -y sudo
    rm -rf /var/lib/apt/lists/*
    useradd -m -s "$(command -v bash)" "${SETUP_USER}"
    echo "${SETUP_USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${SETUP_USER}"
    chmod 0440 "/etc/sudoers.d/${SETUP_USER}"
}

main() {
    install_locale
    create_user
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
