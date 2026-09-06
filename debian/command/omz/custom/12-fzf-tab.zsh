zstyle ":completion:*:*:*:*:*" menu no
zstyle ":completion:*:descriptions" format "[%d]"
zstyle ":completion:*:git-checkout:*" sort false
zstyle ":fzf-tab:complete:cd:*" fzf-preview 'eza -1 --color=always $realpath'
zstyle ":fzf-tab:*" switch-group "<" ">"
