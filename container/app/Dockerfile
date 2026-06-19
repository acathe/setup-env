ARG from=dev-container/terminal:latest

FROM ${from}

ARG git_user_name
ARG git_user_email

COPY ./git.sh /tmp/setup/git.sh
COPY ./vscode.sh /tmp/setup/vscode.sh

RUN bash /tmp/setup/git.sh --git-user-name "${git_user_name}" --git-user-email "${git_user_email}" \
    && bash /tmp/setup/vscode.sh \
    && sudo find /tmp -mindepth 1 -delete
