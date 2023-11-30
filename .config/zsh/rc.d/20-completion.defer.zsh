
# ((${#$(typeset -f compinit | grep -oP 'builtin.*-XUz\K.*$')} > 0)) || return
# [ -n "${DISTROBOX_ENTER_PATH:-}" ] && return

zstyle :compinstall filename "$ZDOTDIR/.zshrc"
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*'              list-dirs-first     true
zstyle ':completion:*'              verbose             true
zstyle ':completion::complete:*'    use-cache           true
zstyle ':completion:*:manuals'      separate-sections   true
zstyle ':completion:*:*:*:*:processes' command "ps -e -u $USER -o pid,user,comm -w -w"
zstyle ':completion:*'              use-cache on
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
#zstyle ':completion:*:*:cp:*' file-sort size

# fzf completion config
# $ZDOTDIR/settings/fzf-preview.sh
zstyle ':fzf-tab:complete:*:*' fzf-preview 'txtpreview.sh ${(Q)realpath}'
#zstyle ':fzf-tab:complete:*:*' fzf-preview 'env LESSOPEN="|$ZDOTDIR/settings/lessfilter.sh %s" less ${(Q)realpath}'

#zstyle ':fzf-tab:complete:*:*:cp:*' file-sort size
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' 'fzf-preview [[ ${group:-} == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=right:'30%':wrap

zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'

zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview 'print -l "\$${(%)${word/#/%B}/%/%b}" ${(P)word}'
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-flags --preview-window=right:'30%':wrap
#zstyle ':fzf-tab:complete:-command-:*' fzf-preview 'txtpreview.sh ${(Q)realpath}'

zstyle ':completion:*:git-checkout:*' sort false
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --color=always $word'
zstyle ':fzf-tab:complete:git-help:*' fzf-preview 'git help $word | bat -plman --color=always'

zstyle ':fzf-tab:complete:tldr:argument-1' fzf-preview 'tldr --color always $word'
zstyle ':fzf-tab:complete:(\\|*/|)man:*' fzf-preview 'man $word'


# zstyle ':completion:complete:*:options' sort false
#autoload bashcompinit
#bashcompinit
#source /etc/profile.d/bash_completion.sh
