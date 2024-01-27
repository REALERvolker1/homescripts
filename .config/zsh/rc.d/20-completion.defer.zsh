
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

# case-insensitive, dash-insensitive
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# zstyle ':completion:*' matcher-list 'r:[[:ascii:]]||[[:ascii:]]=** r:|=* m:{a-z\-}={A-Z\_}'

# I don't want this
#zstyle ':completion:*:*:cp:*' file-sort size

# do not use if you run untrusted completion scripts, as they can run with sudo
#zstyle ':completion::complete:*' gain-privileges 1

# fzf completion config
# This is the generic completion script I use. currently in ~/bin
zstyle ':fzf-tab:complete:*:*' fzf-preview 'txtpreview.zsh ${(Q)realpath}'

# Same as above, I don't want this
#zstyle ':fzf-tab:complete:*:*:cp:*' file-sort size

zstyle ':fzf-tab:complete:(kill|ps):argument-rest' 'fzf-preview [[ ${group:-} == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=right:'30%':wrap

zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'

# The commented-out command will just print the word. I have it set here so it will
# print the key and value if it is a variable or something like that, and it will
# run 'whence' if it isn't.
# zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview 'print -l "[1m$word[0m" ${(P)word}'
zstyle ':fzf-tab:complete:(-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview 'print -l "[1m$word[0m" ${(P)word}'
zstyle ':fzf-tab:complete:-command-:*' fzf-preview 'whence -p $word'

# This is supposed to list my hashed dirs set in 10-environment, 
# but it does jack shit because apparently fzf-tab doesn't support that??? I think it's a bug
zstyle ':fzf-tab:complete:-tilde-:*' fzf-preview 'print "~$word" "=>" ${~word/#/\~}; command ls --color=always --group-directories-first -A ${~word/#/\~}'
# zstyle ':fzf-tab:complete:-tilde-:*' fzf-preview 'echo ${~word/#/\~}'
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-flags --preview-window=right:'30%':wrap

# fzf-tab git commands
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --color=always $word'
zstyle ':fzf-tab:complete:git-help:*' fzf-preview 'git help $word | bat -plman --color=always'

zstyle ':fzf-tab:complete:tldr:argument-1' fzf-preview 'tldr --color always $word'
zstyle ':fzf-tab:complete:(\\|*/|)man:*' fzf-preview 'man $word'

# I think this is stupid
# zstyle ':completion:complete:*:options' sort false

# Use this to load bash completion
#autoload bashcompinit
#bashcompinit
#source /etc/profile.d/bash_completion.sh
