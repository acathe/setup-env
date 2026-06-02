ARG from=dev-container/terminal:latest

FROM ${from}

RUN if [[ -s "$HOME/.zshenv" ]]; then echo >> "$HOME/.zshenv"; fi \
    && echo "# Rust" >> "$HOME/.zshenv" \
    && sed -i '/^plugins=(/s/)/ rust)/' "$HOME/.zshrc"

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && rm -f "$HOME/.profile"
