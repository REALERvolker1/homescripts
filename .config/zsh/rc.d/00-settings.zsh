
# history

HISTFILE="$XDG_STATE_HOME/zshist"
SAVEHIST=50000
HISTSIZE=60000

setopt inc_append_history share_history

setopt hist_ignore_all_dups hist_expire_dups_first

setopt hist_reduce_blanks hist_no_store hist_ignore_space

setopt hist_fcntl_lock

setopt extended_history

# dirplay
setopt auto_cd auto_pushd pushd_ignore_dups multios

# command line
setopt extended_glob glob_complete glob_dots interactive_comments

# prompt
setopt prompt_subst

# Enable the use of Ctrl-Q and Ctrl-S for keyboard shortcuts.
#unsetopt FLOW_CONTROL

#setopt complete_aliases
