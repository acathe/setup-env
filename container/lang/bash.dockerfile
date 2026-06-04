ARG from=dev-container/terminal:latest

FROM ${from}

RUN sudo apt-get update \
    && sudo apt-get install -y shfmt shellcheck \
    && sudo rm -rf /var/lib/apt/lists/*
