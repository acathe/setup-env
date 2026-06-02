ARG from=dev-container/terminal:latest

FROM ${from}

RUN sudo apt-get update \
    && sudo apt-get install -y python3 \
    && sudo rm -rf /var/lib/apt/lists/*

RUN export PATH="$HOME/.local/bin:$PATH" \
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && echo >> "$HOME/.zshrc" \
    && echo '# uv shell completions' >> "$HOME/.zshrc" \
    && echo 'eval "$(uv generate-shell-completion zsh)"' >> "$HOME/.zshrc" \
    && echo 'eval "$(uvx --generate-shell-completion zsh)"' >> "$HOME/.zshrc" \
    && sed -i '/^plugins=(/s/)/ python)/' "$HOME/.zshrc"

RUN mkdir -p "$HOME/.config/Beslogic" \
    && curl -fsSL "https://raw.githubusercontent.com/BesLogic/Beslogic-Ruff-Config/refs/heads/main/ruff.toml" -o "$HOME/.config/Beslogic/ruff.toml"

RUN export PATH="$HOME/.local/bin:$PATH" \
    && uv tool install py-spy
