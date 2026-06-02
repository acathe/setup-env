ARG from=dev-container/base:latest

FROM ${from}

ARG user
ARG git_user_name
ARG git_user_email

RUN sudo apt-get update \
    && sudo apt-get install -y zsh git curl build-essential \
    && sudo rm -rf /var/lib/apt/lists/*

RUN tmpfile="$(mktemp)" \
    && echo '# Sync /etc/profile' >> "$tmpfile" \
    && echo 'emulate sh -c "source /etc/profile"' >> "$tmpfile" \
    && echo >> "$tmpfile" \
    && cat "/etc/zsh/zprofile" >> "$tmpfile" \
    && sudo mv "$tmpfile" "/etc/zsh/zprofile"

RUN git config --global user.name "${git_user_name}" \
    && git config --global user.email "${git_user_email}" \
    && git config --global core.editor "code --wait"

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended \
    && git clone "https://github.com/Pilaton/OhMyZsh-full-autoupdate.git" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/ohmyzsh-full-autoupdate" \
    && git clone "https://github.com/zsh-users/zsh-autosuggestions" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" \
    && git clone "https://github.com/zsh-users/zsh-syntax-highlighting.git" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" \
    && git clone --depth=1 "https://github.com/romkatv/powerlevel10k.git" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

COPY --chown=${user}:${user} ./.p10k.zsh ./.p10k.zsh

RUN sed -i "/export PATH=\$HOME\/bin:\$HOME\/\.local\/bin:\/usr\/local\/bin:\$PATH/s/^# //" "$HOME/.zshrc" \
    && sed -i 's|^ZSH_THEME=".*"|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$HOME/.zshrc" \
    && sed -i '/^plugins=(/s/)/ z sudo vscode ohmyzsh-full-autoupdate zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc" \
    && echo >> "$HOME/.zshrc" \
    && echo '# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.' >> "$HOME/.zshrc" \
    && echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> "$HOME/.zshrc" \
    && sudo -n usermod -s "$(command -v zsh)" "$(whoami)" \
    && rm -f "$HOME/.profile" \
    && rm -f "$HOME/.bashrc" \
    && rm -f "$HOME/.bash_logout"

SHELL ["/usr/bin/zsh", "-c"]
