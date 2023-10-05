# .zshrc
# if ! true "${(q)0}" || [[ -n "${ZSHRC_LOADED:-}" ]] || [[ $- != *i* ]]; then
if [[ -n $ZSH_VERSION && -z $ZSHRC_LOADED && $- == *i* ]]; then
    :
else
    echo "failed to load zshrc"
    return 1
    exit 1
fi

for i in "$ZDOTDIR/rc.d"/*.zsh; do
    #[[ "$i" == *vlkprompt* ]] && continue
    if [[ "$i" == *.defer.zsh ]]; then
        zsh-defer . "$i"
    else
        . "$i"
    fi
done

ZSHRC_LOADED=true
# run /bin/true at the end to clear out any error codes
true
