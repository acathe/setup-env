(
    set -o pipefail
    magpie_update_script="$(curl -fsSL 'https://raw.githubusercontent.com/acathe/setup-env/master/main.sh')" || exit
    printf '%s\n' "$magpie_update_script" \
        | bash -s -- --setup container --image magpie
)
