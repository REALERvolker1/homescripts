
zstyle :compinstall filename "$ZDOTDIR/.zshrc"
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*'              list-dirs-first     true
zstyle ':completion:*'              verbose             true
zstyle ':completion::complete:*'    use-cache           true
zstyle ':completion:*:manuals'      separate-sections   true
zstyle ':completion:*:*:*:*:processes' command "ps -e -u $USER -o pid,user,comm -w -w"

# fzf completion config

zstyle ':fzf-tab:complete:*:*' fzf-preview '$ZDOTDIR/settings/fzf-preview.sh ${(Q)realpath}'
#zstyle ':fzf-tab:complete:*:*' fzf-preview 'env LESSOPEN="|$ZDOTDIR/settings/lessfilter.sh %s" less ${(Q)realpath}'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' 'fzf-preview [[ $group == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=down:3:wrap

zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'

zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview 'echo ${(P)word}'
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --color=always $word'
zstyle ':fzf-tab:complete:git-help:*' fzf-preview 'git help $word | bat -plman --color=always'

zstyle ':fzf-tab:complete:tldr:argument-1' fzf-preview 'tldr --color always $word'
zstyle ':fzf-tab:complete:(\\|*/|)man:*' fzf-preview 'man $word'


#zstyle ':fzf-tab:complete:*:*' fzf-preview 'less ${(Q)realpath}'
#export LESSOPEN='|$ZDOTDIR/lessfilter.zsh %s'


# zstyle ':completion:complete:*:options' sort false
#autoload bashcompinit
#bashcompinit
#source /etc/profile.d/bash_completion.sh
