#!/usr/bin/bash
# shellcheck shell=bash
# vim:foldmethod=marker:ft=sh
## shellcheck disable=2139,2317,2012,1090,1036,1088

typeset -gUA expand_aliases

[[ "$-" == *i* ]] || {
    echo "Error, you must source this file with interactive zsh or bash" >&2
    return 1
    exit 1
}

# global alias, `print hello @n` expands to `print hello &>/dev/null`
alias -g @n='&>/dev/null'

#alias getcargo='bash <(curl -sSf https://sh.rustup.rs) --default-toolchain stable --profile complete --no-modify-path'

# check for all deps first. If not all deps are found, use an alternative fallback config
__lscmd="command ls --color=auto --group-directories-first -A"
__llcmd="$__lscmd -l"
# assign la before we mutate it
# add classifiers@/* if in a vtty, since my lscolors look super similar
alias la="$__lscmd -F"
if [[ ${TERM-} != linux && -z ${DISTROBOX_ENTER_PATH-} && ${+commands[eza]} -ne 0 ]]; then
    __lscmd="eza -AX --group-directories-first --icons=always"
    __llcmd="$__lscmd -lhM --git"
fi

alias ls="$__lscmd" ll="$__llcmd" {sl,l,s}=ls
unset __lscmd __llcmd
for i in {sl,l,s}
    expand_aliases[$i]=ls

# unalias cd, so previous iterations don't get messed up
unalias cd 2>/dev/null
# cd to last directory I was in
alias -- -='cd -'
# cd realpath, resolves symlinks
alias cdrp='cd -P '

alias cp='cp -r'

# alias {us,su}{do,od}='sudo '
alias sudo='sudo '
for i in {us,su}{do,od}
    expand_aliases[$i]=sudo

alias {,:}q=exit

alias shutdown='systemctl poweroff'
alias reboot='systemctl reboot'
alias logout="loginctl kill-session '$XDG_SESSION_ID'"

alias rmf="=rm -rf"
expand_aliases[rmf]='=rm -rf'
#command -v trash &>/dev/null && alias rm='trash -i -r'
alias rm='better-rm'
# remove junk files
for i in "$HOME/".{xsel.log,wget-hsts}
    [[ -e "$i" ]] && command rm "$i"

for i in touch{x{,c,v},c,v}
    alias "$i=__touchx $i"

alias chmodx='chmod +x' chmod-x='chmod -x'
expand_aliases[chmodx]='chmod +x'
alias {\$,%}=''

# alias copy="$__homebin/copy"
alias copycat="=copy --cat"

alias ple='=perl -wlne'
alias gc='=rg --pretty --context=5 --pcre2 --ignore-case'

for i in {,xz,z}{,e,f}grep; do
    alias "$i=$i --color=auto"
done

alias mime='file -bL --mime-type'

alias bap='bat --paging always'
alias glop='glow --pager'
alias bat{op,tio,io}=battop

alias record='pw-record --target "alsa_input.usb-ASUSTeK_COMPUTER_INC._C-Media_R__Audio-00.analog-stereo"'

#alias llama="cd $HOME/src/text-generation-webui && conda run -vvv -n textgen python ./server.py"

alias download='curl -sfLO '
alias ytmp3="yt-dlp --extract-audio --audio-format mp3 "
alias ytmp4="yt-dlp -f bestvideo+bestaudio --sponsorblock-remove sponsor --progress --remux-video mp4 "

if [[ "${TERM:-}" == *'kitty'* ]]; then
    alias icat='kitten icat'
else
    alias icat=chafa
fi

# alias diff=difft
expand_aliases[diff]=difft
# alias extract='ouch decompress'

alias unfuck-old-backup='=tar --hole-detection=seek --keep-directory-symlink -xzf '
alias rsync-archive='rsync -aHAX'

for i in free df du; do
    alias "$i=$i -h"
done

# TODO: migrate from ranger to something better
alias ra=ranger

alias fr='flatpak run'
alias fps='flatpak ps'
alias fjs='firejail --list'
expand_aliases[fr]='flatpak run'
# expand_aliases[fps]='flatpak ps'

alias wget='wget --show-progress'

# alias bg-gen='convert +append -resize x1080'
# alias ttymouse='sudo gpm -m /dev/input/mice -t imps2'

# alias {{vi,iv}{m,},v}="$EDITOR"
for i in ivm vi iv v
    expand_aliases[$i]=vim

expand_aliases[c]=codium

for i in {{b,d,}a,{,r}k,{,t}c,z}sh; do
    alias "$i=run-subshell $i"
done

alias npmi='npm install --global'
alias npml='npm list --global | fzf'

alias tc='tsc && node .'

# TODO: Make dotfiles script the main source of git commands
alias gitm='git add -A && git commit -am "$(date +"Commit from shell alias at %D %r")" '
alias gitp='git pull '
alias tit='echo 😜 && git '
alias gitd='git fetch && git diff "origin/$(git branch | grep -oP "\*[[:space:]]*\K.*\$")"'
alias uncommit='git reset --soft HEAD~'

alias dotm="dotfiles.sh --git commit"
alias dotp="dotfiles.sh --git push"
alias dotd="dotfiles.sh --git diff"
alias dotadd="dotfiles.sh --dotadd"

alias cr='cargo run -- '
alias cb='cargo build'
alias cbr='cargo build --release'

alias cupl='cargo install-update -l'

if ((${+commands[dnf]})); then
    alias dfn=dnf
    expand_aliases[dfn]=dnf
    alias d{nf,fn}i='sudo dnf install'
    alias d{nf,fn}r='sudo dnf remove'
    alias d{nf,fn}u='sudo dnf update --refresh'
    # alias d{nf,fn}s="dnf search "
    alias d{nf,fn}l='dnf list --installed | fzf'
    alias d{nf,fn}a='dnf list --available | fzf'
    alias d{nf,fn}c='dnf check-update'
fi

alias fli='flatpak install'
alias flu='flatpak update'
alias fls='flatpak search' # replaced by ~/bin/flats

alias fll='flatpak list | fzf'
alias flc='flatpak remote-ls --updates'

if ((${+commands[pacman]})); then
    alias unfuck-pacman-cache="sudo pacman -Qk | grep '[^0] missing files'"
    #alias paci='sudo pacman -S --needed '
    alias paci='pacman -Si'
    expand_aliases[paci]='pacman -Si'
    alias paqm='pacman -Qm' # list AUR packages
    alias pacr='sudo pacman -Rcs'
    alias pacl='pacman -Q | fzf'
    alias pacb='pacman -Fl | grep -E "\s+(${PATH//:\//|})" | fzf'
    # alias pacs='pacman -Sl | fzf'
fi

# TODO: make this nicer for wayland too
alias xclassget='xprop | grep WM_CLASS'
alias xkeyget="xev -event keyboard | grep -Eo 'keycode.*\)'"
alias numlock-query="xset q | grep -Po 'Num Lock: *\K[a-z]*'"

alias gpu=switcherooctl
expand_aliases[gpu]=switcherooctl

alias winekill="killall wine{device.exe,server}"
alias winelist="ps -eo args | grep 'C:[/|\\]' | grep -o '^.*\.exe '"
alias ubikill='killall {upc,UbisoftGameLauncher}.exe'

alias steamfix='find "$HOME/.var/app/com.valvesoftware.Steam/.config" -maxdepth 1 -type l -delete'

alias touchpad-gaming='xinput set-prop $(xinput | grep -oP "Touchpad\s*id=\K[0-9]*") "libinput Disable While Typing Enabled" 0'

alias font-reset='fc-cache -fv'
alias font-search="fc-list --format='%{family}\t%{style}\n' | sort | uniq | fzf"

alias pipl='pip list | fzf'
alias printfn="printf '%s\n' "

alias hr='printf "%*s\n" "${COLUMNS:-$(tput cols)}" "" | tr " " -'
alias chars='perl -e "foreach(@ARGV){open(my \$f,\"<\",\"\$_\") or die \"\$!\";my \$c;while(read(\$f,\$c,1)){print \"\$c\n\";}close \$f;}" '

discordify() {
    local file="${1:-}"
    [[ -f $file && -r $file ]] || {
        print "Error, please select a video to format for uploading to Discord!"
        return 1
    }
    if [[ -e ./out.mp4 ]]; then
        print "Error, output file 'out.mp4' already exists! Exiting"
        return 1
    fi
    ffmpeg -i "$file" -map 0 -c:v libx264 -crf 18 -vf format=yuv420p -c:a copy ./out.mp4
}

_vlkrc::dbx::distro() {
    local name="${1:?Error, please specify a distrobox container name!}"
    shift 1
    local -a cmd=("$@")
    ((${#cmd[@]})) || cmd=(bash -l)
    if distrobox-list | cut -d '|' -f 2 | grep -q -m 1 "$name"; then
        distrobox-enter -n "$name" -- "${cmd[@]}"
        return $?
    elif ! command -v distrobox &>/dev/null; then
        echo "Error, you don't seem to have distrobox installed!"
    else
        echo "Error, that distrobox container, '$name', does not exist!"
    fi
    return 1
}

alias ARCH='_vlkrc::dbx::distro ARCH'
alias FEDORA='_vlkrc::dbx::distro FEDORA'
#alias ARCH='distrobox-enter -n ARCH -- bash -l'
#alias FEDORA='distrobox-enter -n FEDORA -- bash -l'

alias fenv='declare | fzf'
alias penv='printenv | fzf'

alias refresh='exec =zsh'
#alias lsh="hash -dL | sed 's/hash -d //g ; s/=/  \t  /g' | fzf"
alias lsh="printf '\e[0;92m~%s\t\e[0;1;94m%s\e[0m\n' \${(@kv)nameddirs}"
alias aliases='printf "\e[1;93m%s\e[0m = \e[92m%s\e[0m\n" "${(@kv)aliases}"'
alias printl='print -l'
expand_aliases[printl]='print -l'
expand_aliases[pl]='print -l'
expand_aliases[p]='print'

expand_aliases[printa]='printf "[%s] %s\n"'
expand_aliases[pa]='printf "[%s] %s\n"'

pkv() {
    local i type type_print type_print_fmt type_print_header
    for i in "$@"; do
        type=${(Pt)${i}}
        type_print="$i: $type"
        type_print_fmt="$i: \e[1m$type"
        type_print_header="─${(l:${#type_print}::─:)}─"

        print -l \
            "\e[0m╭${type_print_header}╮" \
            "│ \e[0m${type_print_fmt}\e[0m │" \
            "╰${type_print_header}╯"
        case $type in
        association*)
            # print -RaC 2 "${(@Pkv)${i}}"
            print -RaC 2 "${(@Pkv)${i}}"
            ;;
        array*)
            print -Rl "${(@P)${i}}"
            ;;
        # scalar*)
        #     print -R "${(P)${i}}"
        #     ;;
        *)
            print -R "${(P)${i}}"
            ;;
        esac
    done
}

alias whi{ch,hc}='__which__function'
expand_aliases[whihc]=which

if command -v grub2-mkconfig &>/dev/null; then
    alias grubcfg='sudo grub2-mkconfig -o /etc/grub2.cfg'
elif command -v grub-mkconfig &>/dev/null; then
    alias grubcfg='sudo grub-mkconfig -o /boot/grub/grub.cfg'
fi

if ((${+commands[nixos-rebuild]})) {
    alias nixup='sudo nixos-rebuild switch --upgrade'
}

if ((! ${+commands[fzf]})); then
    fzf() {
        echo $'\nError, fzf not installed. Falling back to select function\n' >&2
        local -a stdin=()
        while IFS= read -r line; do
            stdin+=("$line")
        done
        select i in "${stdin[@]}"; do
            echo "$i"
            break
        done
    }
fi