# .zshrc
if [ -z "${ZSH_VERSION:-}" ] || [ -n "${ZSHRC_LOADED:-}" ] || [[ $- != *i* ]] 2>/dev/null; then
    echo "doublesourced $0"
    return
    exit
fi
#{ [ -n "${ZSH_VERSION:-}" ] && [ -z "${ZSHRC_LOADED:-}" ] && [[ $- == *i* ]] } || return || exit

# A note to any beleaguered viewers of my public dotfiles: browse .config/zsh/rc.d

for i in "$ZDOTDIR/rc.d"/*.zsh; do
    #[[ "$i" == *vlkprompt* ]] && continue
    if [[ "$i" == *.defer.zsh ]]; then
        # lazy-load
        zsh-defer . "$i"
    else
        . "$i"
    fi
done

ZSHRC_LOADED=true
# run /bin/true at the end to clear out any error codes
true
