#!/usr/bin/env bash

set -euo pipefail

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

set_completion() {
    local completion="$1"

    local completion_dir
    completion_dir="$(brew --prefix)/share/zsh/site-functions"

    if [[ ! -f "$completion_dir/$completion" ]]; then
        echo "$completion_dir/$completion does not exist." >&2
        return 1
    fi

    mkdir -p "$ZSH_CUSTOM/completions"
    ln -sf "$completion_dir/$completion" "$ZSH_CUSTOM/completions/$completion"
}

set_completions() {
    set_completion '_distrobox'
    set_completion '_distrobox-assemble'
    set_completion '_distrobox-create'
    set_completion '_distrobox-enter'
    set_completion '_distrobox-ephemeral'
    set_completion '_distrobox-export'
    set_completion '_distrobox-generate-entry'
    set_completion '_distrobox-host-exec'
    set_completion '_distrobox-init'
    set_completion '_distrobox-list'
    set_completion '_distrobox-rm'
    set_completion '_distrobox-stop'
    set_completion '_distrobox-upgrade'
    set_completion '_distrobox_containers'
    set_completion '_distrobox_images'
    set_completion '_distrobox_running_containers'
}

set_config() {
    echo "container_home_prefix=\"$HOME/distrobox\"" > "$HOME/.config/distrobox/distrobox.conf"

}

main() {
    if ! command -v docker > /dev/null 2>&1; then
        echo 'Docker is not installed.' >&2
        return 1
    fi

    brew install 'distrobox'
    set_completions
    set_config
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
