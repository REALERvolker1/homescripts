[[ -n ${ZSH_VERSION-} && -o i && -t 0 && -t 1 && -t 2 ]] || {
    echo "failed to load zshrc"
    return 1
    exit 1
}
\builtin unset ZSHRC_LOADED

# I want to eliminate system-defined aliases. Change this on whatever distro.
# It def helps to not have '{' aliased to 'rm -rf ~/* &>/dev/null &!'
#printf '%s => %s\n' "${(@kv)aliases}"
\builtin unalias "${(@k)aliases}" cd &>/dev/null
## This is helpful if you use nix and you really need global aliases for some reason
#\builtin unalias ${(@k)builtins} ${(@k)reswords} &>/dev/null

# reset all, including font. Also reset the cursor
alias unfuck="print -n '\e[0m''\e(B\e)0\017\e[?5l\e7\e[0;0r\e8''\e[0 q'"
# run the reset command and then clear the screen
unfuck && print -n '\e[H\e[2J'

# Load environment variables and other shell unfucking
. ${ZDOTDIR:-~}/environ.zsh

# This is really only here so my prompt doesn't show my hostname when on my main pc
# It is only here because I'm lazy and I would forget to remove it if it were anywhere else
CURRENT_HOSTNAME='iphone'

### shell session settings
# VLKPROMPT_SKIP=1  # Skip custom prompt, use the fallback
# VLKPLUG_SKIP=1    # Skip all plugin init
# VLKATUIN_SKIP=1   # Skip atuin, it is broken on linux vtty

# make ctrl+S not freeze the terminal
stty stop undef

# I set and unset many options, so I don't get surprised by weird settings
setopt inc_append_history share_history \
    hist_ignore_all_dups hist_expire_dups_first \
    hist_reduce_blanks hist_no_store hist_ignore_space \
    hist_fcntl_lock extended_history \
    \
    auto_cd auto_pushd cdable_vars pushd_ignore_dups multios extended_glob glob_dots \
    \
    glob_complete complete_in_word complete_aliases \
    interactive_comments prompt_subst no_bg_nice correct rm_star_wait

unsetopt hist_no_functions all_export global_export mark_dirs null_glob \
    no_unset err_exit pipefail

# use if I ever decide to try zsh from emacs
# [[ $EMACS = t ]] && unsetopt zle

# load zsh modules -- the -a flag means 'autoload', but is temperamental with stuff like zsh/pcre
zmodload zsh/pcre
# only load the zstat component, because I have stat already
zmodload -aF zsh/stat b:zstat

# in safe mode, several things are disabled to improve compatibility with weird environments.
typeset -ig VLKZSH_SAFEMODE=0
if ((VLKZSH_SAFEMODE)) || [[ $TERM == linux || $TTY == /dev/tty* || $COLORTERM != truecolor ]] {
    VLKZSH_SAFEMODE=1
    # make truecolors behave well in TTY
    zmodload zsh/nearcolor

    # if we're in a VTTY, start tmux
    if [[ $TERM == linux && ${TTY:-$(tty)} == /dev/tty* ]] && (($+commands[tmux])); then
        exec tmux
    fi
}

# Idea: debug mode function. When run, it adds useful stuff like lines/cols
# and persistent exec time and whatever to my prompt

# Certain files like vlkrc and vlkenv from ~/bin are loaded along with other settings files
# I am using zsh-defer to load some of the less-essential ones
foreach i ("${ZDOTDIR:-~/.config/zsh}/rc.d"/*.zsh) {
    if [[ $i == *.defer.zsh ]] {
        zsh-defer . "$i"
    } else {
        . "$i"
    }
}

# Autoload all my functions
for i in "$ZDOTDIR/functions"/^*.zwc(.N)
    autoload $i

# remove junk files
for i in "$HOME/".{xsel.log,wget-hsts}
    [[ -e "$i" ]] && command rm "$i"

# Track stty changes between prompts, ask me if I want to accept any changes
zsh-defer zstatectl --track

# zoxide cd
alias cd=z

# My custom fetchscript
dumbfetch

# Print a fortune in italics, pass through lolcat for formatting
print -n '\e[0;3m'
fortune -a -s | lolcat
print -n '\e[0m'

# Run to see if you need to unfunction anything
for i in ${(@k)builtins} ${(@k)aliases} ${(@k)reswords}; (($+functions[$i])) && echo $i

# Execute lsdiff unless I don't need to
[[ -z ${DISTROBOX_ENTER_PATH-} ]] && lsdiff

# Knowing me, I probably set i somewhere
unset i
# Keep track of if zsh was loaded, don't re-source my zshrc if so
typeset -i ZSHRC_LOADED=1

