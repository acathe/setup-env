export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND/ --type f/}"
export FZF_ALT_C_COMMAND="${FZF_DEFAULT_COMMAND/--type f/--type d}"
export FZF_CTRL_T_OPTS='--preview "case $(file -Lb --mime-type -- {}) in inode/directory) eza -TL 2 --color=always --group-directories-first -- {} ;; text/*) bat -p --color=always -- {} ;; *) file -Lb -- {} ;; esac"'
export FZF_ALT_C_OPTS='--preview "eza -TL 2 --color=always --group-directories-first -- {}"'
