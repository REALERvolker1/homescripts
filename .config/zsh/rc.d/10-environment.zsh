setopt inc_append_history share_history \
    hist_ignore_all_dups hist_expire_dups_first \
    hist_reduce_blanks hist_no_store hist_ignore_space \
    hist_fcntl_lock extended_history \
    auto_cd auto_pushd pushd_ignore_dups multios \
    extended_glob glob_complete complete_in_word glob_dots interactive_comments \
    prompt_subst nobgnice

for i in \
    zsh="$ZDOTDIR" \
    bin="$HOME/bin" \
    code="$HOME/code" \
    pics="$HOME/Pictures" \
    var="$HOME/.var/app" \
    dots="$HOMESCRIPTS" \
    loc="$HOME/.local" \
    data="$XDG_DATA_HOME" \
    cache="$XDG_CACHE_HOME" \
    cfg="$XDG_CONFIG_HOME" \
    run="$XDG_RUNTIME_DIR" \
    rnd="$HOME/random" \
    i3="$XDG_CONFIG_HOME/i3" \
    hypr="$XDG_CONFIG_HOME/hypr"; do
    hash -d "$i"
done
fpath=("$ZDOTDIR/site-functions" $fpath)
export -U PATH path FPATH fpath
export -U XDG_DATA_DIRS
export -U chpwd_functions
export -U precmd_functions

HISTFILE="$XDG_STATE_HOME/zshist"
SAVEHIST=50000
HISTSIZE=60000

PROMPT='%k%f
%B %F{14}%~%f %(0?.%F{10}%#.%F{9}%? %#) %b%f'
ZLE_RPROMPT_INDENT=0
PROMPT_EOL_MARK=''

export ZPLUGIN_DIR="$XDG_DATA_HOME/zsh-plugins"
__vlk_zsh_plugins=(
    "Aloxaf/fzf-tab"
    "zdharma-continuum/fast-syntax-highlighting"
    "zsh-users/zsh-autosuggestions"
)
for i in "$ZDOTDIR/functions"/^*.zwc(.N); do
    [[ -f "$i" ]] && autoload -Uz "$i"
done

__cd_ls() {
    local -i fcount="$(printf '%s\n' ./*(N) | wc -l)"
    ((fcount < 30)) && { ls; return; }
    echo -e "\e[${${${LS_COLORS:-01;34}##*:di=}%%:*}m${fcount}\e[0m items in this folder"
}
chpwd_functions+=('__cd_ls')