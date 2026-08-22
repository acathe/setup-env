export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND/ --type f/}"
export FZF_ALT_C_COMMAND="${FZF_DEFAULT_COMMAND/--type f/--type d}"
export FZF_CTRL_T_OPTS='--preview "if [ -d {} ]; then eza --tree --level=2 --color=always --icons=never --group-directories-first -- {}; else bat -p --color=always -- {}; fi"'
export FZF_ALT_C_OPTS='--preview "eza --tree --level=2 --color=always --icons=never --group-directories-first -- {}"'
