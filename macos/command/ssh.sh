#!/usr/bin/env bash

set -euo pipefail

COMMAND_SSH_HOST="${COMMAND_SSH_HOST:-}"
COMMAND_SSH_HOSTNAME="${COMMAND_SSH_HOSTNAME:-}"
COMMAND_SSH_USER="${COMMAND_SSH_USER:-$USER}"
COMMAND_SSH_IDENTITY_FILE="${COMMAND_SSH_IDENTITY_FILE:-}"
COMMAND_SSH_COMMENT="${COMMAND_SSH_COMMENT:-}"
COMMAND_SSH_COPY_KEY="${COMMAND_SSH_COPY_KEY:-1}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --command-ssh-host)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    COMMAND_SSH_HOST="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --command-ssh-hostname)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    COMMAND_SSH_HOSTNAME="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --command-ssh-user)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    COMMAND_SSH_USER="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --command-ssh-identity-file)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    COMMAND_SSH_IDENTITY_FILE="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --command-ssh-comment)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    COMMAND_SSH_COMMENT="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --command-ssh-no-copy-key)
                COMMAND_SSH_COPY_KEY=0
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
    if [[ -z $COMMAND_SSH_IDENTITY_FILE ]]; then
        echo 'COMMAND_SSH_IDENTITY_FILE is required.' >&2
        return 1
    fi

    local identity_file="$HOME/.ssh/$COMMAND_SSH_IDENTITY_FILE"

    if [[ -f $identity_file ]]; then
        echo "$identity_file already exists, skip generating." >&2
        return 0
    fi

    (
        umask 077
        mkdir -p "$(dirname "$identity_file")"
    )

    local args=(-f "$identity_file")
    if [[ -n $COMMAND_SSH_COMMENT ]]; then
        args+=(-C "$COMMAND_SSH_COMMENT")
    fi

    ssh-keygen "${args[@]}"
}

add_config() {
    if [[ -z $COMMAND_SSH_HOST || -z $COMMAND_SSH_HOSTNAME || -z $COMMAND_SSH_USER ]]; then
        echo 'COMMAND_SSH_HOST, COMMAND_SSH_HOSTNAME and COMMAND_SSH_USER are required.' >&2
        return 1
    fi

    local config_file="$HOME/.ssh/config"
    touch "$config_file"
    chmod 600 "$config_file"

    if [[ -s $config_file ]]; then
        echo >> "$config_file"
    fi

    {
        echo "Host $COMMAND_SSH_HOST"
        echo "    HostName $COMMAND_SSH_HOSTNAME"
        echo "    User $COMMAND_SSH_USER"
        if [[ -n $COMMAND_SSH_IDENTITY_FILE ]]; then
            echo "    IdentityFile ~/.ssh/$COMMAND_SSH_IDENTITY_FILE"
        fi
    } >> "$config_file"
}

main() {
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    if [[ -n $COMMAND_SSH_IDENTITY_FILE ]]; then
        gen_key
    fi

    add_config

    if [[ $COMMAND_SSH_COPY_KEY == '1' && -n $COMMAND_SSH_IDENTITY_FILE ]]; then
        ssh-copy-id -i "$HOME/.ssh/$COMMAND_SSH_IDENTITY_FILE.pub" "$COMMAND_SSH_HOST"
    fi
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]+"${POSITIONAL[@]}"}" # restore positional params
    main "$@"
fi
