#!/usr/bin/env bash

set -euo pipefail

install_omz() {
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

install_plugin() {
    git clone "https://github.com/Pilaton/OhMyZsh-full-autoupdate.git" \
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/ohmyzsh-full-autoupdate"
    git clone "https://github.com/zsh-users/zsh-autosuggestions" \
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    git clone "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    git clone --depth=1 "https://github.com/romkatv/powerlevel10k.git" \
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
}

install_p10k() {
    cp ./p10k.zsh "$HOME/.p10k.zsh"
}

config_zshrc() {
    sed -i "/export PATH=\$HOME\/bin:\$HOME\/\.local\/bin:\/usr\/local\/bin:\$PATH/s/^# //" "$HOME/.zshrc"
    sed -i 's|^ZSH_THEME=".*"|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$HOME/.zshrc"
    sed -i 's/^plugins=(.*)/plugins=(z sudo ohmyzsh-full-autoupdate zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"

    {
        echo ""
        echo '# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.'
        echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh'
    } >> "$HOME/.zshrc"
}

set_default_shell() {
    sudo -n usermod -s "$(command -v zsh)" "$(whoami)"
}

remove_bash_startup_files() {
    rm -f "$HOME/.profile"
    rm -f "$HOME/.bashrc"
    rm -f "$HOME/.bash_logout"
}

main() {
    install_omz
    install_plugin
    install_p10k
    config_zshrc
    set_default_shell
    remove_bash_startup_files
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    main "$@"
fi
