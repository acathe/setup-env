ARG from=dev-container/base:latest

FROM ${from}

ARG user
ARG git_user_name
ARG git_user_email

COPY ./zsh.sh /tmp/setup/zsh.sh
COPY ./git.sh /tmp/setup/git.sh
COPY ./omz.sh /tmp/setup/omz.sh
COPY ./vscode.sh /tmp/setup/vscode.sh
COPY ./.p10k.zsh /tmp/setup/.p10k.zsh

RUN bash /tmp/setup/zsh.sh \
    && bash /tmp/setup/omz.sh \
    && bash /tmp/setup/git.sh --git-user-name "${git_user_name}" --git-user-email "${git_user_email}" \
    && bash /tmp/setup/vscode.sh \
    && sudo rm -rf /var/lib/apt/lists/* \
    && sudo find /tmp -mindepth 1 -delete

SHELL ["/usr/bin/zsh", "-c"]
