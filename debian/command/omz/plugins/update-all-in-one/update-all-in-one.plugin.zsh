update-all-in-one() {
    local update_script

    for update_script in "$ZSH_CUSTOM/plugins/update-all-in-one/custom"/*.zsh; do
        source "$update_script"
    done
}
