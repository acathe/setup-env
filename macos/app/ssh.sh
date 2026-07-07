#!/usr/bin/env bash

set -euo pipefail

APP_SSH_HOST="${APP_SSH_HOST:-}"
APP_SSH_HOSTNAME="${APP_SSH_HOSTNAME:-}"
APP_SSH_USER="${APP_SSH_USER:-"$USER"}"
APP_SSH_IDENTITY_FILE="${APP_SSH_IDENTITY_FILE:-}"
APP_SSH_COMMENT="${APP_SSH_COMMENT:-}"
APP_SSH_COPY_KEY="${APP_SSH_COPY_KEY:-1}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --app-ssh-host)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    APP_SSH_HOST="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --app-ssh-hostname)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    APP_SSH_HOSTNAME="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --app-ssh-user)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    APP_SSH_USER="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --app-ssh-identity-file)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    APP_SSH_IDENTITY_FILE="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --app-ssh-comment)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    APP_SSH_COMMENT="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --app-ssh-no-copy-key)
                APP_SSH_COPY_KEY=0
                shift # shift once since flags have no values
                ;;
            *) # unknown flag/switch
                POSITIONAL+=("$1")
                shift
                ;;
        esac
    done
}

gen_key() {
    if [[ -z $APP_SSH_IDENTITY_FILE ]]; then
        echo "APP_SSH_IDENTITY_FILE is required." >&2
        return 1
    fi

    local identity_file="$HOME/.ssh/$APP_SSH_IDENTITY_FILE"

    if [[ -f $identity_file ]]; then
        echo "$identity_file already exists, skip generating." >&2
        return 0
    fi

    (
        umask 077
        mkdir -p "$(dirname "$identity_file")"
    )

    local args=(-f "$identity_file")
    if [[ -n $APP_SSH_COMMENT ]]; then
        args+=(-C "$APP_SSH_COMMENT")
    fi

    ssh-keygen "${args[@]}"
}

add_config() {
    if [[ -z $APP_SSH_HOST || -z $APP_SSH_HOSTNAME || -z $APP_SSH_USER ]]; then
        echo "APP_SSH_HOST, APP_SSH_HOSTNAME and APP_SSH_USER are required." >&2
        return 1
    fi

    local config_file="$HOME/.ssh/config"
    touch "$config_file"
    chmod 600 "$config_file"

    if [[ -s $config_file ]]; then
        echo >> "$config_file"
    fi

    {
        echo "Host $APP_SSH_HOST"
        echo "    HostName $APP_SSH_HOSTNAME"
        echo "    User $APP_SSH_USER"
        if [[ -n $APP_SSH_IDENTITY_FILE ]]; then
            echo "    IdentityFile $HOME/.ssh/$APP_SSH_IDENTITY_FILE"
        fi
    } >> "$config_file"
}

main() {
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    if [[ -n $APP_SSH_IDENTITY_FILE ]]; then
        gen_key
    fi

    add_config

    if [[ $APP_SSH_COPY_KEY == "1" && -n $APP_SSH_IDENTITY_FILE ]]; then
        ssh-copy-id -i "$HOME/.ssh/$APP_SSH_IDENTITY_FILE.pub" "$APP_SSH_HOST"
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]+"${POSITIONAL[@]}"}" # restore positional params
    main "$@"
fi
