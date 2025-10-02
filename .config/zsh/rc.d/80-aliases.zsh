#!/usr/bin/zsh
# vim:foldmethod=marker:ft=zsh

# This is my "aliasrc". I keep all my shell functions in $ZDOTDIR/functions, so that they are autoloaded.

# I have a bunch of aliases that only expand when I hit spacebar.
# This works with the `expand_alias` function in my zsh keybindings.
# That looks something like this:
#
# if ((${+expand_aliases[${LBUFFER// }]} && ! ${+commands[${LBUFFER// }]})); then
#         LBUFFER="${expand_aliases[${LBUFFER// }]}"
#
# It is bound to spacebar, so when I type "rmf" and hit space, for example, it
# automatically expands to `rm -rf`.
#
# It is very useful, and it explains a lot why I am adding keys and values to
# an array like you would just normally add an alias.

# typeset global unique association
typeset -gUA expand_aliases

[[ -o i ]] || {
    echo "Error, you must source this file with interactive zsh" >&2
    return 1
    exit 1
}

# global alias, `print hello @n` expands to `print hello &>/dev/null`
alias -g @n='&>/dev/null'
alias -g @t='| tee'
alias -g @p="| ${PAGER:-less}"

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

mkcd() {
    mkdir "$@"
    cd "$@"
}

# I am not really sure that all my scripts are root-safe,
# running broken shell scripts as sudo is generally frowned upon
# alias sudo='sudo '
for i in {us,su}{do,od}
    expand_aliases[$i]=sudo

alias su=sudo

alias {,:}q=exit

# requires systemd
alias shutdown='systemctl poweroff'
alias reboot='systemctl reboot'

# logout only works on login shells. This makes it work everywhere.
[[ -n ${XDG_SESSION_ID-} ]] && alias logout="loginctl kill-session '$XDG_SESSION_ID'"

# rm -rf. I set the alias as well as the expand here just for a failsafe
alias rmf='=rm -rf'
expand_aliases[rmf]='=rm -rf'
#command -v trash &>/dev/null && alias rm='trash -i -r'
alias rm='better-rm'
for i in touch{x{,c,v},c,v}
    alias "$i=__touchx $i"

# set executable bit, for scripts
alias chmodx='chmod +x' chmod-x='chmod -x'
expand_aliases[chmodx]='chmod +x'

# make it ignore stuff copied from the internet like `$ ls`
alias {\$,%}=''

# copy a file's contents using my copy script
alias copycat="=copy --cat"

# run perl like `blah blah blah | ple '$%)@$(*&#)@'`  (That garbage is probably valid perl syntax somewhere)
alias ple='=perl -wlne'

# grep with context
alias gc='=rg --pretty --context=5 --pcre2 --ignore-case'

# all of Fedora's massive colorgrep script, in only 2 lines
for i in {,xz,z}{,e,f}grep
    alias "$i=$i --color=auto"

alias mime='file -bL --mime-type'

# bat/glow with paging
alias bap='bat --paging always'
alias glop='glow --pager'

# I always misspell this command
alias bat{op,tio,io}=battop

# record audio with pipewire
alias record='=pw-record --target "alsa_input.usb-ASUSTeK_COMPUTER_INC._C-Media_R__Audio-00.analog-stereo"'

# download something without changing the name
alias download='=curl -sfLO '
# download from youtube
alias ytmp3="=yt-dlp --extract-audio --audio-format mp3 "
alias ytmp4="=yt-dlp -f bestvideo+bestaudio --sponsorblock-remove sponsor --progress --remux-video mp4 "

alias nmapa="=nmap -Av 192.168.0.'*'"

expand_aliases[uncrlf]='sed -i $'\''s/\r\n$/\n/g'\'
alias uncrlf=:

# so I can see what's plugged into what
# Does not show device names for some reason
# alias lsusb='=lsusb -t'

# terminal image viewers
# also, kitty-specific ssh thing that makes ssh nicer
if [[ ${TERM-} == *kitty* ]]; then
    alias icat='kitten icat'
    alias ssh='kitten ssh'
else
    alias icat=chafa
fi

# difftastic
alias diff=difft

# use this if the extract zsh function doesn't work
# alias extract='ouch decompress'

# interact with backups
alias unfuck-old-backup='=tar --hole-detection=seek --keep-directory-symlink -xzf '
# copy a file to a drive better
alias rsync-archive='rsync -aHAX'

# human-readable output
for i in free df du
    alias "$i=$i -h"

# TODO: migrate from ranger to something better
# yazi was not better, the dev refuses to add LS_COLORS because they are a cringe windows user and they don't like being able to find their files
alias ra=ranger

# flatpak aliases
alias fr='flatpak run'
alias fps='flatpak ps'
expand_aliases[fr]='flatpak run'

# firejail is another sandboxing program
alias fjs='firejail --list'

# wget2 is better and shows progress automatically
if (($+commands[wget2])); then
    alias wget=wget2
else
    alias wget='wget --show-progress'
fi

# turn 2 images into one giant image
# alias bg-gen='convert +append -resize x1080'
alias ttymouse='sudo gpm -m /dev/input/mice -t imps2'

# I have been having this issue with Arch recently that sddm just shits itself on boot and needs to be restarted
[[ ${TERM-} == linux ]] && alias sddm-unfucker='sudo systemctl restart sddm.service && logout'

alias {{vi,iv}{m,},v}=${EDITOR:-nvim}
for i in ivm vi iv v
    expand_aliases[$i]=vim

# bash dash ash ksh rksh csh tcsh zsh
# I want to set up the environment for them
# no, my syntax highlighter isn't happy either.
for i in {{b,d,}a,{,r}k,{,t}c,z}sh
    alias "$i=run-subshell $i"

# nodejs
alias npmi='npm install --global'
alias npml='npm list --global | fzf'

alias tc='tsc && node .'

# TODO: Make dotfiles script the main source of git commands
# alias gitm='git add -A && git commit -am "$(date +"Commit from shell alias at %D %r")" '
alias gitm='git add -A && git commit -a'
alias gitp='git pull'
alias tit='echo 😜 && git '
alias gitd='git fetch && git diff "origin/$(git branch | grep -oP "\*[[:space:]]*\K.*\$")"'
alias uncommit='git reset --soft HEAD~'

# interact with my dotfiles
alias dotm="dotfiles.sh --git commit"
alias dotp="dotfiles.sh --git push"
alias dotd="dotfiles.sh --git diff"
alias dotadd="dotfiles.sh --dotadd"

# useful cargo aliases
alias cr='cargo run'
alias crr='cargo run --release'
# pass command line args too
expand_aliases[cr]='cr --'
# alias cb='cargo build'
# for distribution, run cargo build --release. This is only for local dev.
alias cbr='RUSTFLAGS="-C target-cpu=native" cargo build --release'

cbc() {
    local -a cargs=(-Wall -fuse-ld=mold -march=native -mtune=native)
    if [[ ${1-} == --debug ]]; then
        cargs+=(-O0 -g)
    else
        cargs+=(-Ofast -flto=full)
    fi
    clang $cargs ./**/*.c(.) -o ${PWD##*/}
}

if (($+commands[dnf])); then
    # all kinds of Fedora aliases
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

if (($+commands[pacman])); then
    alias unfuck-pacman-cache="sudo pacman -Qk | grep '[^0] missing files'"
    #alias paci='sudo pacman -S --needed '
    alias paci='pacman -Si'
    expand_aliases[paci]='pacman -Si'
    alias paqm='pacman -Qm' # list AUR packages
    alias pacr='sudo pacman -Rcs'
    alias pacl='pacman -Q | fzf'
    alias pacb='pacman -Fl | grep -E "\s+(${PATH//:\//|})" | fzf'
    alias pacsi='sudo pacman -S --needed'
    # expand_aliases[pacss]='sudo pacman -S'
    alias reflect='sudo reflector "@/etc/xdg/reflector/reflector.conf" --save /etc/pacman.d/mirrorlist'
    # alias pacs='pacman -Sl | fzf' # I have a script for this
fi

# TODO: make this nicer for wayland too
# alias xclassget='xprop | grep WM_CLASS'
# alias xkeyget="xev -event keyboard | grep -Eo 'keycode.*\)'"
# alias numlock-query="xset q | grep -Po 'Num Lock: *\K[a-z]*'"

alias gpu=switcherooctl

# wine and other gaming aliases
alias winekill="killall wine{device.exe,server}"
alias winelist="ps -eo args | grep 'C:[/|\\]' | grep -o '^.*\.exe '"
alias ubikill='killall {upc,UbisoftGameLauncher}.exe'

# Steam flatpak doesn't like symlinks -- https://github.com/flathub/com.valvesoftware.Steam/issues/1089
# The issue might be marked as resolved, but this bug keeps popping up. Remove if not needed.
alias steamfix='find "$HOME/.var/app/com.valvesoftware.Steam/.config" -maxdepth 1 -type l -delete'

# turn off DWT so I can use my touchpad and keyboard at the same time in games while using xorg
alias touchpad-gaming='xinput set-prop $(xinput | grep -oP "Touchpad\s*id=\K[0-9]*") "libinput Disable While Typing Enabled" 0'

alias font-reset='fc-cache -fv'
alias font-search="fc-list --format='%{family}\t%{style}\n' | sort | uniq | fzf"

alias pipl='pip list | fzf'
alias printfn="printf '%s\n' "

# Print a horizontal row of dashes
alias hr='print -- ${(l:COLUMNS::-:)}'
# alias hr='printf "%*s\n" "${COLUMNS:-$(tput cols)}" "" | tr " " -' # The bash-compatible version

# enter my distroboxes. This uses an autoloaded function defined in $ZDOTDIR/functions/_vlkrc::dbx::distro
alias ARCH='_vlkrc::dbx::distro ARCH'
alias FEDORA='_vlkrc::dbx::distro FEDORA'
#alias ARCH='distrobox-enter -n ARCH -- bash -l'
#alias FEDORA='distrobox-enter -n FEDORA -- bash -l'

# fenv shows all variables, penv only shows exported (typeset -x) variables
alias fenv='declare | fzf'
alias penv='printenv | fzf'

# I don't want to double-source my zshrc
alias refresh='exec =zsh'


# print on separate lines
alias printl='print -l'
expand_aliases[printl]='print -l'
expand_aliases[pl]='print -l'
expand_aliases[p]='print'
expand_aliases[e]='echo'

# print associations (assoc arrays) as [key] value
expand_aliases[printa]='printf "[%s] %s\n"'
expand_aliases[pa]='printf "[%s] %s\n"'

# I have my own handler for this in my zsh autoloaded functions
alias whi{ch,hc}='__which__function'
expand_aliases[whihc]=which

# build grub config on arch and fedora
if command -v grub2-mkconfig &>/dev/null; then
    alias grubcfg='sudo grub2-mkconfig -o /etc/grub2.cfg'
elif command -v grub-mkconfig &>/dev/null; then
    alias grubcfg='sudo grub-mkconfig -o /boot/grub/grub.cfg'
fi

# if ((${+commands[nixos-rebuild]})) {
    # alias nixup='sudo nixos-rebuild switch --upgrade'
# }

# A lot of my stuff depends on fzf. I want my shell to work.
# TODO: Verify this function works in zsh
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
#!/usr/bin/zsh
# vim:foldmethod=marker:ft=zsh

# I have a bunch of aliases that only expand when I hit spacebar.
# This works with the `expand_alias` function in my zsh keybindings.
