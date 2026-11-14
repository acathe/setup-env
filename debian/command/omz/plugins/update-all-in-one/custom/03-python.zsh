uv python upgrade -q \
    && uv tool upgrade -q --all

mkdir -p "$HOME/.config/ruff"
curl -fsSL 'https://raw.githubusercontent.com/BesLogic/Beslogic-Ruff-Config/refs/heads/main/ruff.toml' \
    -o "$HOME/.config/ruff/ruff.toml"
