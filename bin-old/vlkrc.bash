#!/usr/bin/bash
# shellcheck shell=bash
# vim:foldmethod=marker:ft=sh
## shellcheck disable=2139,2317,2012,1090,1036,1088

[[ "$-" == *i* ]] || {
    echo "Error, you must source this file with interactive zsh or bash" >&2
    return 1
    exit 1
}

#alias getcargo='bash <(curl -sSf https://sh.rustup.rs) --default-toolchain stable --profile complete --no-modify-path'

__homebin="$HOME/bin"

# check for all deps first. If not all deps are found, use an alternative fallback config
__lscmd="command ls --color=auto --group-directories-first -A"
__llcmd="$__lscmd -l"
# assign la before we mutate it
# add classifiers@/* if in a vtty, since my lscolors look super similar
alias la="$__lscmd -F"
if [[ ${TERM-} != linux && -z ${DISTROBOX_ENTER_PATH-} ]] && command -v eza >/dev/null 2>&1; then
    __lscmd="eza -AX --group-directories-first --icons=always"
    __llcmd="$__lscmd -lhM --git"
fi

alias {{sl,l,s},ls}="$__lscmd " ll="$__llcmd "
unset __lscmd __llcmd

# unalias cd, so previous iterations don't get messed up
unalias cd 2>/dev/null
# cd to last directory I was in
alias -- -='cd -'
# cd realpath, resolves symlinks
alias cdrp='cd -P '

rp() {
    if [[ -z "${1:-}" ]]; then
        realpath "$PWD"
    else
        local i
        for i in "$@"; do
            realpath "$i"
        done
    fi
}

alias cp='cp -r'

alias {us,su}{do,od}='sudo '
alias {,:}q=exit

alias shutdown='systemctl poweroff'
alias reboot='systemctl reboot'
alias logout="loginctl kill-session '$XDG_SESSION_ID'"

alias rmf="$(command which rm) -rf"
#command -v trash &>/dev/null && alias rm='trash -i -r'
alias rm='better-rm '
# remove junk files
for i in "$HOME/".{xsel.log,wget-hsts}; do
    [[ -e "$i" ]] && rmf "$i"
done

__touchx() {
    local op="${1#touch}"
    shift 1

    local editor
    if [[ "$op" == *c ]]; then
        editor=codium
    elif [[ "$op" == *v ]]; then
        editor="${EDITOR:-vim}"
    else
        editor=echo
    fi

    for file in "$@"; do
        touch "$file"
        [[ "$op" == x* ]] && chmod +x "$file"
        $editor "$file"
    done
}

for i in touch{x{,c,v},c,v}; do
    alias "$i=__touchx $i"
done

alias chmodx='chmod +x' chmod-x='chmod -x'

[[ -z ${BASH_VERSION-} ]] && alias {\$,%}=''

alias copy="$__homebin/copy"
alias copycat="$__homebin/copy --cat"

alias ple='perl -wlne '
alias gc='rg --pretty --context=5 --pcre2 --ignore-case '

for i in {,xz,z}{,e,f}grep; do
    alias "$i=$i --color=auto"
done

alias mime='file -bL --mime-type'

alias bap='bat --paging always'
alias glop='glow --pager'
alias bat{op,tio,io}=battop

alias record='pw-record --target "alsa_input.usb-ASUSTeK_COMPUTER_INC._C-Media_R__Audio-00.analog-stereo" '

whisp-py() {
    # designed for use with openai whisper
    # pip install --user --upgrade --no-deps --force-reinstall git+https://github.com/openai/whisper.git ; pip install --user blobfile
    local -a whispargs=(--language en --device cuda --model medium.en --output_format txt)
    echo "starting whisper with args '${whispargs[*]} $*'"
    whisper "${whispargs[@]}" "$@"
}
whisp() {
    # designed for use with whisper.cpp
    # https://github.com/ggerganov/whisper.cpp
    local model="$HOME/random/whisper-cpp/ggml-medium.en.bin"
    local file="${1-}"
    file="$(realpath "$file" || :)"
    local file_base="${file%/*}"
    if [[ ! -f "$file" ]]; then
        echo "Error, please input an audio file!"
        return 1
    fi
    if [[ ! -f "${model-}" ]]; then
        echo "Error, model '${model-}' does not seem to be installed!"
        return 2
    fi
    if [[ ! -w "${file_base-}" ]]; then
        echo "Error, file basepath '${file_base-}' is not writable!"
        return 3
    fi
    # whisper.cpp is very picky about the wav format
    local mydir="${XDG_CACHE_HOME:=$HOME/.cache}/whisp"
    local myfile="$mydir/${file##*/}"
    local oldpwd="${PWD:=$(pwd)}"
    (
        # make temporary cache dir
        mkdir -p "$mydir"
        builtin cd "$mydir"
        # ffmpeg writes new file to temporary output myfile
        command ffmpeg -i "$file" -acodec pcm_s16le -ar 16000 "$myfile"
    ) || return
    local -a whispargs=(--output-txt --print-colors --print-progress --language en --model "$model" -f "$myfile")
    echo "starting whisper with args '${whispargs[*]} $*'"
    whisper.cpp "${whispargs[@]}"
    # remove temporary output file, move all other files
    command rm "$myfile"
    command mv -i "$mydir"/* "$file_base"
    builtin cd "$oldpwd" || return
    command rm -r "$mydir"
}

#alias llama="cd $HOME/src/text-generation-webui && conda run -vvv -n textgen python ./server.py"

alias download='curl -sfLO '
alias ytmp3="yt-dlp --extract-audio --audio-format mp3 "
alias ytmp4="yt-dlp -f bestvideo+bestaudio --sponsorblock-remove sponsor --progress --remux-video mp4 "

if [[ "${TERM:-}" == *'kitty'* ]]; then
    alias icat='kitten icat'
else
    alias icat=chafa
fi

alias diff=difft
# alias extract='ouch decompress'

alias unfuck-old-backup='tar --hole-detection=seek --keep-directory-symlink -xzf '
alias rsync-archive='rsync -aHAX'

for i in free df du; do
    alias "$i=$i -h"
done

# TODO: migrate from ranger to something better
alias ra=ranger

alias fr='flatpak run'
alias fps='flatpak ps'
alias fjs='firejail --list'

alias wget='wget --show-progress'

# alias bg-gen='convert +append -resize x1080'
# alias ttymouse='sudo gpm -m /dev/input/mice -t imps2'

alias {{vi,iv}{m,},v}="$EDITOR"

run-subshell() {
    [[ -n ${ZSH_VERSION-} ]] && ttyctl -f
    cmd="${1:-}"
    [[ ${cmd:-} =~ (|t)csh ]] && echo 💀
    command -v "$cmd" >/dev/null || return
    shift 1
    HISTFILE="${SHELLHIST:-/dev/null}" $cmd "$@"
    local -i retval="$?"
    [[ -n ${ZSH_VERSION-} ]] && ttyctl -u
    return $retval
}

for i in {{b,d,}a,{,r}k,{,t}c,z}sh; do
    alias "$i=run-subshell $i"
done

venv() {
    local venv="$PWD/venv"
    local venvb="$venv/bin/activate"
    if [[ -f "$venvb" ]]; then
        source "$venvb"
    else
        python -m venv "$venv"
        if [[ -f "$venvb" ]]; then
            source "$venvb"
        else
            echo "Error, failed to find python venv"
            return 1
        fi
    fi
}

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
alias cbr='cargo build --release'
cn() {
    local projname="${1:?Error, please enter a project name!}"
    echo -n "Press ENTER to create a new Rust program '$projname' in this directory"
    local ans
    read -r ans
    [[ $ans == '' ]] || return
    cargo new "$projname" || return
    builtin cd "$PWD/$projname" || return
    codium ./
}
alias cupl='cargo install-update -l'

if command -v dnf &>/dev/null; then
    alias dfn=dnf
    alias d{nf,fn}i='sudo dnf install '
    alias d{nf,fn}r='sudo dnf remove '
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

if command -v pacman &>/dev/null; then
    alias unfuck-pacman-cache="sudo pacman -Qk | grep '[^0] missing files'"
    #alias paci='sudo pacman -S --needed '
    alias paci='pacman -Si'
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

if [[ -n "${ZSH_VERSION:-}" ]]; then
    alias refresh='exec zsh'
    #alias lsh="hash -dL | sed 's/hash -d //g ; s/=/  \t  /g' | fzf"
    alias lsh="printf '\e[0;92m~%s\t\e[0;1;94m%s\e[0m\n' \${(@kv)nameddirs}"
    alias aliases='printf "\e[1;93m%s\e[0m = \e[92m%s\e[0m\n" "${(@kv)aliases}"'
    alias printl='print -l'
    alias whi{ch,hc}='__which__function'

elif [[ -n "${BASH_VERSION:-}" ]]; then
    alias refresh='exec bash'
    alias whi{ch,hc}='(alias; declare -f) | command which --tty-only --read-alias --read-functions --show-tilde --show-dot'
fi

if command -v grub2-mkconfig &>/dev/null; then
    alias grubcfg='sudo grub2-mkconfig -o /etc/grub2.cfg'
elif command -v grub-mkconfig &>/dev/null; then
    alias grubcfg='sudo grub-mkconfig -o /boot/grub/grub.cfg'
fi

unset __homebin

gitc() {
    if [[ "$PWD" == "$HOME" ]]; then
        echo "Error: don't clone a git repo to '$PWD'!"
        return 1
    fi
    local git_link="${1?:Error. Specify link to clone}"
    local git_dir="$PWD/${git_link##*/}"
    git_dir="${git_dir%.git}"
    echo -e "Cloning \033[4m$git_link\033[0m "
    git clone "$git_link" "$git_dir"
    cd "$git_dir" || return 1
}

readme() {
    : "${1:=$(printf '%s\n' ./* | grep -i 'readme' | fzf --select-1)}"
    if command -v 'glow' &>/dev/null; then
        glow "$1"
    elif command -v 'bat' &>/dev/null; then
        bat "$1"
    else
        cat "$1"
    fi
}

mnt() {
    local disk="${1:?Error, no disk path selected!}"
    local mount="${2:?Error, no mountpoint selected!}"
    if [[ ! -b $disk ]]; then
        lsblk -o NAME,LABEL,PATH,FSTYPE,SIZE,FSUSE%,MOUNTPOINT
        echo "Error, path provided '${disk:-}' is not a disk!"
        return 1
    elif [[ $mount != '/mnt'* ]]; then
        echo "Error, must mount to directory '/mnt'! Invalid mountpoint '$mount'"
        return 1
    elif [[ ! -d ${2:-} ]]; then
        if [[ -e $mount || -L $mount ]]; then
            echo "Error, mountpoint '$mount' is not a directory!"
            return 1
        fi
        echo "Want to make directory '$mount'?"
        local ans
        read -r ans
        [[ ${ans:-} == y ]] || return 1
    fi
    local -a mountargs=()
    local fstype
    fstype="$(lsblk -no FSTYPE "$disk" || :)"
    case "${fstype:-}" in
    ext4 | vfat | xfs) : ;;
    btrfs)
        mountargs+=(-o "compress=zstd:5,noatime")
        ;;
    *)
        echo "Error, current fstype not supported at the moment!"
        return 1
        ;;
    esac
    mountargs+=("$disk" "$mount")

    printf '\n%s' \
        'Are you sure you want to mount?' \
        "${mountargs[*]}" \
        '[y/N] > '
    local ans
    read -r ans
    [[ ${ans:-} == y ]] || return 1
    sudo mount "${mountargs[@]}"
    cd "$mount" || return 1
}

if ! command -v fzf &>/dev/null; then
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
