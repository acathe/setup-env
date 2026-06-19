FROM debian:trixie

ARG user
ARG lang
ARG encoding
ARG language
ARG tz
ARG term=xterm-256color
ARG git_user_name
ARG git_user_email

ENV LANG=${lang}.${encoding}
ENV LANGUAGE=${language}
ENV TZ=${tz}
ENV TERM=${term}

SHELL ["/usr/bin/bash", "-c"]

COPY ./terminal/base.sh /tmp/setup/base.sh
RUN bash /tmp/setup/base.sh --user "${user}" --lang "${lang}" --encoding "${encoding}" \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

WORKDIR /home/${user}
USER ${user}

RUN sudo apt-get update \
    && sudo apt-get install -y git curl \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

COPY ./terminal/zsh.sh /tmp/setup/zsh.sh
RUN bash /tmp/setup/zsh.sh \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

COPY ./terminal/omz/main.sh /tmp/setup/omz/main.sh
COPY ./terminal/omz/p10k.zsh /tmp/setup/omz/p10k.zsh
RUN bash /tmp/setup/omz/main.sh \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

COPY ./app/git.sh /tmp/setup/git.sh
RUN bash /tmp/setup/git.sh --git-user-name "${git_user_name}" --git-user-email "${git_user_email}" \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

COPY ./app/vscode.sh /tmp/setup/vscode.sh
RUN bash /tmp/setup/vscode.sh \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

COPY ./lang/bash.sh /tmp/setup/bash.sh
RUN bash /tmp/setup/bash.sh \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

COPY ./lang/go.sh /tmp/setup/go.sh
RUN bash /tmp/setup/go.sh \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

COPY ./lang/python.sh /tmp/setup/python.sh
RUN bash /tmp/setup/python.sh \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

COPY ./lang/rust.sh /tmp/setup/rust.sh
RUN bash /tmp/setup/rust.sh \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

COPY ./tools/protobuf.sh /tmp/setup/protobuf.sh
RUN bash /tmp/setup/protobuf.sh \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/*

SHELL ["/usr/bin/zsh", "-c"]

CMD ["sleep", "infinity"]
