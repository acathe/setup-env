FROM debian:trixie

ARG lang
ARG encoding
ARG language
ARG tz
ARG term=xterm-256color

ENV LANG=${lang}.${encoding}
ENV LANGUAGE=${language}
ENV TZ=${tz}
ENV TERM=${term}

SHELL ["/usr/bin/bash", "-c"]

ARG user
RUN apt-get update \
    && apt-get install -y locales sudo \
    && localedef -i ${lang} -c -f ${encoding} -A /usr/share/locale/locale.alias ${lang}.${encoding} \
    && useradd -m -s "$(command -v bash)" "${user}" \
    && echo "${user} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${user}" \
    && chmod 0440 "/etc/sudoers.d/${user}" \
    && rm -rf /var/lib/apt/lists/* /tmp/*

WORKDIR /home/${user}
USER ${user}
ENV USER=${user}

RUN sudo apt-get update \
    && sudo apt-get install -y git curl \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

RUN --mount=type=bind,source=.,target=/mnt/setup,readonly \
    bash /mnt/setup/terminal/zsh.sh \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

RUN --mount=type=bind,source=.,target=/mnt/setup,readonly \
    bash /mnt/setup/terminal/omz/main.sh --unattended \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

ARG app_git_user_name
ARG app_git_user_email
RUN --mount=type=bind,source=.,target=/mnt/setup,readonly \
    bash /mnt/setup/app/git.sh --app-git-user-name "${app_git_user_name}" --app-git-user-email "${app_git_user_email}" \
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
    bash /mnt/setup/tool/protobuf.sh \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

CMD ["sleep", "infinity"]
