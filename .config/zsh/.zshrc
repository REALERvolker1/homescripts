# .zshrc
[ -z "${ZSH_VERSION:-}" ] && return

# A note to any beleaguered viewers of my public dotfiles: browse .config/zsh/rc.d

for i in "$ZDOTDIR/rc.d"/*.zsh; do
    # [[ "$i" == *vlkprompt* ]] && continue
    if [[ "$i" == *.defer.zsh ]]; then
        # lazy-load
        zsh-defer . "$i"
    else
        . "$i"
    fi
done

# run /bin/true at the end to clear out any error codes
true
