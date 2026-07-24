#!/usr/bin/env bash

set -euo pipefail

COMMAND_UTILS_GIT_USER_NAME="${COMMAND_UTILS_GIT_USER_NAME:-}"
COMMAND_UTILS_GIT_USER_EMAIL="${COMMAND_UTILS_GIT_USER_EMAIL:-}"

APP_MICRO="${APP_MICRO:-0}"

parse_args() {
    POSITIONAL=()
    while (($# > 0)); do
        case "$1" in
            --command-utils-git-user-name)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    COMMAND_UTILS_GIT_USER_NAME="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            --command-utils-git-user-email)
                numOfArgs=1 # number of switch arguments
                if (($# < numOfArgs + 1)); then
                    shift $#
                else
                    COMMAND_UTILS_GIT_USER_EMAIL="$2"
                    shift $((numOfArgs + 1)) # shift 'numOfArgs + 1' to bypass switch and its value
                fi
                ;;
            *) # unknown flag/switch
                POSITIONAL+=("$1")
                shift
                ;;
        esac
    done
}

setup_git() {
    if [[ -n $COMMAND_UTILS_GIT_USER_NAME ]]; then
        git config --global user.name "$COMMAND_UTILS_GIT_USER_NAME"
    fi
    if [[ -n $COMMAND_UTILS_GIT_USER_EMAIL ]]; then
        git config --global user.email "$COMMAND_UTILS_GIT_USER_EMAIL"
    fi

    # git-delta 作为 diff 分页器
    git config --global core.pager delta
    git config --global interactive.diffFilter 'delta --color-only'
    git config --global delta.navigate true
    git config --global delta.line-numbers true
    git config --global merge.conflictStyle zdiff3

    sed -i '/^plugins=(/s/)/ git)/' "$HOME/.zshrc"
}

configure_zshrc() {
    # zoxide 取代 omz 的 z 插件；同新增一样用一行 sed 删除
    # \< \> 词边界只删完整的 z，不误伤 zsh-* 等
    sed -i '/^plugins=(/{ s/\<z\> \+//; s/ \+\<z\>//; }' "$HOME/.zshrc"

    # fzf-tab：用 fzf 界面接管 Tab 补全。必须早于 zsh-autosuggestions /
    # zsh-syntax-highlighting 加载，故「头插」到 plugins 开头（对称于尾插 s/)/ x)/）
    git clone "https://github.com/Aloxaf/fzf-tab" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab"
    sed -i '/^plugins=(/s/(/(fzf-tab /' "$HOME/.zshrc"

    if [[ -s "$HOME/.zshrc" ]]; then echo >> "$HOME/.zshrc"; fi

    {
        echo '# Modern CLI tools'
        # Debian 二进制改名坑：恢复习惯名
        echo "alias bat='batcat'"
        echo "alias fd='fdfind'"
        # eza 取代 ls / tree（omz 的 ll/la/l 会经别名递归复用 ls）
        echo "alias ls='eza --group-directories-first'"
        echo "alias tree='eza --tree'"
        # micro 只读别名（仅当同时启用 --app-micro）
        if [[ $APP_MICRO == "1" ]]; then
            echo "alias micror='micro -readonly true'"
        fi
        # shell 集成
        echo 'eval "$(zoxide init zsh)"'
        echo 'eval "$(fzf --zsh)"'
        # yazi 官方 shell wrapper：以 y 启动，退出时 cd 到浏览的目录
        echo 'function y() {'
        echo '    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd'
        echo '    command yazi "$@" --cwd-file="$tmp"'
        echo '    IFS= read -r -d '\'''\'' cwd < "$tmp"'
        echo '    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"'
        echo '    command rm -f -- "$tmp"'
        echo '}'
    } >> "$HOME/.zshrc"
}

install_binaries() {
    # apt 无 yazi/choose，取官方 release 二进制装入 /usr/local/bin
    local tmp
    tmp="$(mktemp -d)"

    # yazi 终端文件管理器（zip 内为同名子目录，含 yazi 与 ya 两个可执行文件）
    curl -fsSL -o "$tmp/yazi.zip" \
        "https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip"
    unzip -q "$tmp/yazi.zip" -d "$tmp"
    sudo install -m 755 "$tmp/yazi-x86_64-unknown-linux-gnu/yazi" /usr/local/bin/yazi
    sudo install -m 755 "$tmp/yazi-x86_64-unknown-linux-gnu/ya" /usr/local/bin/ya

    # choose（cut 的人性化替代，裸 ELF 二进制，无需解压）
    curl -fsSL -o "$tmp/choose" \
        "https://github.com/theryangeary/choose/releases/latest/download/choose-x86_64-unknown-linux-gnu"
    sudo install -m 755 "$tmp/choose" /usr/local/bin/choose
}

main() {
    sudo apt-get update
    sudo apt-get install -y \
        jq \
        unzip \
        glow \
        eza \
        bat \
        fd-find \
        ripgrep \
        zoxide \
        fzf \
        git-delta \
        tealdeer \
        hyperfine \
        sd \
        lazygit \
        btop \
        du-dust \
        duf \
        procs

    tldr --update || true # 预热 tealdeer 离线缓存，网络失败不致命

    install_binaries
    setup_git
    configure_zshrc
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
    parse_args "$@"
    set -- "${POSITIONAL[@]}" # restore positional params
    main "$@"
fi
