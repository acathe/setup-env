FROM debian:trixie

ARG user
ARG lang_code
ARG encoding
ARG language
ARG tz
ARG term=xterm-256color
ARG git_user_name
ARG git_user_email

ENV LANG=${lang_code}.${encoding}
ENV LANGUAGE=${language}
ENV TZ=${tz}
ENV TERM=${term}

SHELL ["/usr/bin/bash", "-c"]

RUN --mount=type=bind,source=.,target=/mnt/setup,readonly \
    bash /mnt/setup/terminal/root.sh --user "${user}" --lang-code "${lang_code}" --encoding "${encoding}" \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

WORKDIR /home/${user}
USER ${user}

RUN sudo apt-get update \
    && sudo apt-get install -y git curl \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

RUN --mount=type=bind,source=.,target=/mnt/setup,readonly \
    bash /mnt/setup/terminal/zsh.sh \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

RUN --mount=type=bind,source=.,target=/mnt/setup,readonly \
    bash /mnt/setup/terminal/omz/main.sh \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

SHELL ["/usr/bin/zsh", "-c"]

RUN --mount=type=bind,source=.,target=/mnt/setup,readonly \
    bash /mnt/setup/app/git.sh --git-user-name "${git_user_name}" --git-user-email "${git_user_email}" \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

RUN --mount=type=bind,source=.,target=/mnt/setup,readonly \
    bash /mnt/setup/app/vscode.sh \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

RUN --mount=type=bind,source=.,target=/mnt/setup,readonly \
    bash /mnt/setup/lang/bash.sh \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

RUN --mount=type=bind,source=.,target=/mnt/setup,readonly \
    bash /mnt/setup/lang/go.sh \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

RUN --mount=type=bind,source=.,target=/mnt/setup,readonly \
    bash /mnt/setup/lang/python.sh \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

RUN --mount=type=bind,source=.,target=/mnt/setup,readonly \
    bash /mnt/setup/lang/rust.sh \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

RUN --mount=type=bind,source=.,target=/mnt/setup,readonly \
    bash /mnt/setup/tools/protobuf.sh \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

CMD ["sleep", "infinity"]
