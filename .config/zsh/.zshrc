# .zshrc
[ -z "${ZSH_VERSION:-}" ] && return

for i in "$ZDOTDIR/rc.d"/*.zsh; do
    if [[ "$i" == *.defer.* ]]; then
        zsh-defer . "$i"
    else
        . "$i"
    fi
done

true
