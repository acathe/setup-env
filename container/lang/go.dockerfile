ARG from=dev-container/terminal:latest

FROM ${from}

RUN go_version="$(curl -fsSL 'https://go.dev/dl/?mode=json' | grep -o 'go.*.linux-amd64.tar.gz' | head -n 1 | tr -d '\r\n')" \
    && curl -fsSL "https://go.dev/dl/$go_version" -o "/tmp/$go_version" \
    && sudo tar -C "/usr/local" -xzf "/tmp/$go_version" \
    && rm -f "/tmp/$go_version"

RUN export PATH="/usr/local/go/bin:$PATH" \
    && echo >> "$HOME/.zshrc" \
    && echo '# Go' >> "$HOME/.zshrc" \
    && echo 'export PATH="$PATH:/usr/local/go/bin"' >> "$HOME/.zshrc" \
    && echo 'export PATH="$HOME/go/bin:$PATH"' >> "$HOME/.zshrc" \
    && sed -i '/^plugins=(/s/)/ golang)/' "$HOME/.zshrc"
