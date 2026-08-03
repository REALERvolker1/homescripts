
# ((${#$(typeset -f compinit | grep -oP 'builtin.*-XUz\K.*$')} > 0)) || return
# [ -n "${DISTROBOX_ENTER_PATH:-}" ] && return

# install completion from my zshrc
zstyle :compinstall filename "${ZDOTDIR:-$HOME}/.zshrc"
autoload -Uz compinit
# make my completion directory if it doesn't exist for some reason
[[ -d $XDG_CACHE_HOME/zsh ]] || \mkdir -p $XDG_CACHE_HOME/zsh
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"

zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# This does jack shit
zstyle ':completion:*' list-dirs-first true

zstyle ':completion:*' verbose true
zstyle ':completion::complete:*' use-cache true
zstyle ':completion:*' use-cache true

zstyle ':completion:*:manuals' separate-sections true
# shows processes upon completion request
zstyle ':completion:*:*:*:*:processes' command "ps -e -u $USER -o pid,user,comm -w -w"

zstyle ':completion:*' completer _complete _match _approximate
# three strikes before it gives up
zstyle ':completion:*:approximate:*' max-errors 3 numeric

# offer indexes before parameters in subscripts
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# case-insensitive, dash-insensitive
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# ignore completion functions (until the _ignored completer)
# doesn't do jack shit on my config
zstyle ':completion:*:functions' ignored-patterns '_*'

# formatting and messages
# copied over from zsh-git example zshrc with no testing whatsoever. Will configure later
# zstyle ':completion:*' verbose yes
# zstyle ':completion:*:descriptions' format '%B%d%b'
# zstyle ':completion:*:messages' format '%d'
# zstyle ':completion:*:warnings' format 'No matches for: %d'
# zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
# zstyle ':completion:*' group-name ''

# zstyle ':completion:*' matcher-list 'r:[[:ascii:]]||[[:ascii:]]=** r:|=* m:{a-z\-}={A-Z\_}'

# I don't want this
#zstyle ':completion:*:*:cp:*' file-sort size

# do not use if you run untrusted completion scripts, as they can run with sudo
#zstyle ':completion::complete:*' gain-privileges 1

# fzf completion config
# fzf provides the exact preview dimensions. Export the conventional shell
# variables as well so every preview command and its children see them.
typeset -gr __vlk_fzf_preview_env='typeset -gx COLUMNS=${FZF_PREVIEW_COLUMNS:-${COLUMNS:-80}} LINES=${FZF_PREVIEW_LINES:-${LINES:-24}}'

# Start without reserving space for a preview. File-backed candidates reveal
# the window on focus; candidates without a real path leave it hidden.
# fzf-tab 24105b1 generates a broken {_FTB_INIT_} helper that reads a literal
# `$1` path. It still loads the capture arrays, so reconstruct the selected
# item's metadata from those arrays before deciding whether to show the window.
typeset -gr __vlk_fzf_preview_metadata='{_FTB_INIT_} desc=${${"$(<''{f}'')"%$'"'"'\0'"'"'*}#*$'"'"'\0'"'"'}; local -A ctxt=("${(@0)${_ftb_compcap[(r)${(b)desc}$bs*]#*$bs}}"); word=${(Q)ctxt[word]}; unset realpath group; (( $+ctxt[realdir] )) && realpath=${ctxt[realdir]}$word; (( $+ctxt[group] )) && group=$_ftb_groups[$ctxt[group]]; '
typeset -gr __vlk_fzf_file_preview_binding="focus:transform:exec 2>/dev/null; $__vlk_fzf_preview_metadata"'[[ -n ${realpath-} ]] && print "change-preview-window(right,50%,nohidden)" || print "change-preview-window(hidden)"'
typeset -gr __vlk_fzf_process_preview_binding="focus:transform:exec 2>/dev/null; $__vlk_fzf_preview_metadata"'[[ ${group:-} == "[process ID]" ]] && print "change-preview-window(right,30%,wrap,nohidden)" || print "change-preview-window(hidden)"'
typeset -gr __vlk_fzf_show_preview_binding='focus:change-preview-window(right,50%,nohidden)'
typeset -gr __vlk_fzf_show_narrow_preview_binding='focus:change-preview-window(right,30%,wrap,nohidden)'

# Source txtpreview in this shell. Launching it through its Zsh shebang resets
# the special COLUMNS/LINES parameters back to the outer terminal dimensions.
zstyle ':fzf-tab:complete:*:*' fzf-preview "$__vlk_fzf_preview_env"'; [[ -n ${realpath-} ]] && source =txtpreview.zsh ${(Q)realpath}'
zstyle ':fzf-tab:complete:*:*' fzf-flags --preview-window=right:'50%':hidden
zstyle ':fzf-tab:complete:*:*' fzf-bindings "$__vlk_fzf_file_preview_binding"

# Same as above, I don't want this
#zstyle ':fzf-tab:complete:*:*:cp:*' file-sort size

zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview "$__vlk_fzf_preview_env"'; [[ ${group:-} == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=right:'30%':wrap
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-bindings "$__vlk_fzf_process_preview_binding"

zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview "$__vlk_fzf_preview_env; SYSTEMD_COLORS=1 systemctl status \$word"
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-bindings "$__vlk_fzf_show_preview_binding"

# The commented-out command will just print the word. I have it set here so it will
# print the key and value if it is a variable or something like that, and it will
# run 'whence' if it isn't.
# zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview 'print -l "[1m$word[0m" ${(P)word}'
zstyle ':fzf-tab:complete:(-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview "$__vlk_fzf_preview_env; print -l \"[1m\$word[0m\" \${(P)word}"
zstyle ':fzf-tab:complete:-command-:*' fzf-preview "$__vlk_fzf_preview_env; whence -p \$word"
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-bindings "$__vlk_fzf_show_narrow_preview_binding"

# This is supposed to list my hashed dirs set in 10-environment, 
# but it does jack shit because apparently fzf-tab doesn't support that??? I think it's a bug
zstyle ':fzf-tab:complete:-tilde-:*' fzf-preview "$__vlk_fzf_preview_env; print \"~\$word\" \"=>\" \${~word/#/\\~}; command ls --color=always --group-directories-first -A \${~word/#/\\~}"
zstyle ':fzf-tab:complete:-tilde-:*' fzf-bindings "$__vlk_fzf_show_preview_binding"
# zstyle ':fzf-tab:complete:-tilde-:*' fzf-preview 'echo ${~word/#/\~}'
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-flags --preview-window=right:'30%':wrap

# fzf-tab git commands
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview "$__vlk_fzf_preview_env; git diff \$word | delta"
zstyle ':fzf-tab:complete:git-log:*' fzf-preview "$__vlk_fzf_preview_env; git log --color=always \$word"
zstyle ':fzf-tab:complete:git-help:*' fzf-preview "$__vlk_fzf_preview_env; git help \$word | bat -plman --color=always"
zstyle ':fzf-tab:complete:git-(add|diff|restore|log|help):*' fzf-bindings "$__vlk_fzf_show_preview_binding"

zstyle ':fzf-tab:complete:tldr:argument-1' fzf-preview "$__vlk_fzf_preview_env; tldr --color always \$word"
zstyle ':fzf-tab:complete:tldr:argument-1' fzf-bindings "$__vlk_fzf_show_preview_binding"
zstyle ':fzf-tab:complete:(\\|*/|)man:*' fzf-preview "$__vlk_fzf_preview_env; man \$word"
zstyle ':fzf-tab:complete:(\\|*/|)man:*' fzf-bindings "$__vlk_fzf_show_preview_binding"

# I think this is stupid
# zstyle ':completion:complete:*:options' sort false

# Use this to load bash completion
#autoload bashcompinit
#bashcompinit
#source /etc/profile.d/bash_completion.sh
