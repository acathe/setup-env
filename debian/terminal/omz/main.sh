#!/usr/bin/env bash

set -euo pipefail

UNATTENDED="${UNATTENDED:-0}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --unattended)
                UNATTENDED=1
                shift
                ;;
            *) # unknown flag/switch
                POSITIONAL+=("$1")
                shift
                ;;
        esac
    done
}

install_omz() {
    if ! command -v git > /dev/null 2>&1; then
        echo "git is not installed." >&2
        return 1
    fi

    if ! command -v curl > /dev/null 2>&1; then
        echo "curl is not installed." >&2
        return 1
    fi

    if [[ $UNATTENDED == "1" ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        sudo -n usermod -s "$(command -v zsh)" "$(whoami)"
    else
        RUNZSH="no" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi

    if [[ -s "$HOME/.zshrc.pre-oh-my-zsh" ]]; then
        local tmpfile
        tmpfile="$(mktemp)"
        cp "$HOME/.zshrc" "$tmpfile"

        {
            cat "$HOME/.zshrc.pre-oh-my-zsh"
            echo ""
            cat "$tmpfile"
        } > "$HOME/.zshrc"
    fi

    rm -f "$HOME/.zshrc.pre-oh-my-zsh"
}

install_plugin() {
    if ! command -v git > /dev/null 2>&1; then
        echo "git is not installed." >&2
        return 1
    fi

    sed -i 's/^plugins=(.*)/plugins=(z sudo)/' "$HOME/.zshrc"

    # Ref. https://github.com/Pilaton/OhMyZsh-full-autoupdate?tab=readme-ov-file#installing
    git clone "https://github.com/Pilaton/OhMyZsh-full-autoupdate.git" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/ohmyzsh-full-autoupdate"
    sed -i '/^plugins=(/s/)/ ohmyzsh-full-autoupdate)/' "$HOME/.zshrc"

    # Ref. https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md#oh-my-zsh
    git clone "https://github.com/zsh-users/zsh-autosuggestions" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    sed -i '/^plugins=(/s/)/ zsh-autosuggestions)/' "$HOME/.zshrc"

    # Ref. https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md/#Oh-my-zsh
    git clone "https://github.com/zsh-users/zsh-syntax-highlighting.git" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    sed -i '/^plugins=(/s/)/ zsh-syntax-highlighting)/' "$HOME/.zshrc"

    # Ref. https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#oh-my-zsh
    git clone --depth=1 "https://github.com/romkatv/powerlevel10k.git" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    sed -i 's|^ZSH_THEME=".*"|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$HOME/.zshrc"
}

remove_preshell() {
    if [[ ! -f "$HOME/.shell.pre-oh-my-zsh" ]]; then
        return 0
    fi

    sed -i "/export PATH=\$HOME\/bin:\$HOME\/\.local\/bin:\/usr\/local\/bin:\$PATH/s/^# //" "$HOME/.zshrc"

    rm -f "$HOME/.shell.pre-oh-my-zsh"
    rm -f "$HOME/.profile"
    rm -f "$HOME/.bashrc"
    rm -f "$HOME/.bash_logout"

    if [[ $UNATTENDED == "1" ]]; then
        cp "$SCRIPT_DIR/p10k.zsh" "$HOME/.p10k.zsh"
        {
            echo ""
            echo '# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.'
            echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh'
        } >> "$HOME/.zshrc"
    fi

}

main() {
    install_omz
    install_plugin
    remove_preshell
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
