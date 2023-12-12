#!/usr/bin/zsh
emulate -L zsh
set -euo pipefail

# required dependencies
typeset -a deperr
for i in file pandoc exiftool chafa ffmpeg bat stat ls lsof pidstat rm pdfinfo pdftotext
    ((${+commands[$i]})) || deperr+=($i)

if ((${#deperr})); then
    print -l "Error, missing dependencies" $deperr
    return 1
fi

typeset -a chafacmd=(chafa --format=symbols --symbols all --animate=off)

typeset -a mdcmd
if ((${+commands[glow]})); then
    mdcmd=(glow)
else
    print "'glow' not found, falling back to 'bat'"
    mdcmd=(bat -l md)
fi

typeset -a lscolorcmd
if ((${+commands[lscolors]})); then
    lscolorcmd=(lscolors)
else
    print "'lscolors' not found, falling back to 'ls'"
    lscolorcmd=(ls --color=always -d)
fi

typeset -a lscmd
typeset -a fallbackcmd
if ((${+commands[eza]})); then
    lscmd=(eza -AX --group-directories-first --color=always --icons=always)
    fallbackcmd=(eza -AldhMX --git --color=always --icons=always)
elif ((${+commands[lsd]})); then
    lscmd=(lsd --ignore-config --icon=always --color=always -AL)
    fallbackcmd=(lsd --ignore-config --icon=always --color=always -lLd)
else
    lscmd=(ls --group-directories-first --color=always -AF)
    fallbackcmd=(ls --color=always -AlLFd)
fi

view::fallback::path() {
    # $fallbackcmd "$@"

    local size_disp
    local label=bytes
    local size_color=1

    # initialize for pretty-printing stuff
    local -a pre_stat
    pre_stat=(${(@f)$(stat -c $'%s\n%A\n%a' $1 2>/dev/null || print $'0\t----------\t000')})
    # get human-readable form
    local size_bytes=$pre_stat[1]
    # size_bytes="$(stat -c '%s' $1 2>/dev/null || print 0)"

    local -i kilobyte=1000
    local -i megabyte=1000000
    local -i gigabyte=1000000000
    local -i gb=$((size_bytes / gigabyte))
    local -i mb=$((size_bytes / megabyte))
    local -i kb=$((size_bytes / kilobyte))

    local -i modunit=0
    if ((gb)); then
        modunit=$gigabyte
        size_disp=$gb
        size_color=4
        label=GB
    elif ((mb)); then
        modunit=$megabyte
        size_disp=$mb
        size_color=2
        label=MB
    elif ((kb)); then
        modunit=$kilobyte
        size_disp=$kb
        size_color=3
        label=KB
    else
        size_disp='%s'
        size_color=5
        label=B
    fi
    if ((modunit)); then
        local re
        local -i decimal
        re="$((size_bytes % modunit))000"
        re="${re::2}"
        decimal=${re::1}
        ((${re:1:1} > 4)) && ((decimal++))
        if ((decimal)); then
            size_disp="${size_disp}.$decimal"
        else
            size_disp="${size_disp}"
        fi
    fi

    local human_perms=$pre_stat[2]
    local -a perm_arr=()
    # human_perms="$(stat -c '%A' $1 2>/dev/null)"

    if [[ $human_perms[1] == - ]]; then
        perm_arr+=("[0;90m${human_perms[1]}")
    else
        perm_arr+=("${$(ls --color=always -d $1)%%/*}${human_perms[1]}")
    fi

    local hcolor hperm
    # owner
    hperm=$human_perms[2] hcolor=90
    [[ $hperm != - ]] && hcolor=33
    perm_arr+=("[0;1;${hcolor}m${hperm}")

    hperm=$human_perms[3] hcolor=90
    [[ $hperm != - ]] && hcolor=31
    perm_arr+=("[0;1;${hcolor}m${hperm}")

    hperm=$human_perms[4] hcolor=90
    [[ $hperm != - ]] && hcolor=32
    perm_arr+=("[0;1;${hcolor}m${hperm}")

    # group
    hperm=$human_perms[5] hcolor=90
    [[ $hperm != - ]] && hcolor=33
    perm_arr+=("[0;${hcolor}m${hperm}")

    hperm=$human_perms[6] hcolor=90
    [[ $hperm != - ]] && hcolor=31
    perm_arr+=("[0;${hcolor}m${hperm}")

    hperm=$human_perms[7] hcolor=90
    [[ $hperm != - ]] && hcolor=32
    perm_arr+=("[0;${hcolor}m${hperm}")

    # all users
    hperm=$human_perms[8] hcolor=90
    [[ $hperm != - ]] && hcolor=33
    perm_arr+=("[0;${hcolor}m${hperm}")

    hperm=$human_perms[9] hcolor=90
    [[ $hperm != - ]] && hcolor=31
    perm_arr+=("[0;${hcolor}m${hperm}")

    hperm=$human_perms[10] hcolor=90
    [[ $hperm != - ]] && hcolor=32
    perm_arr+=("[0;${hcolor}m${hperm}")

    local -a octal_perms=(${(s..)${pre_stat[3]}})
    octal_perms[1]="[1;9${octal_perms[1]}m${octal_perms[1]}"
    octal_perms[2]="[2;3${octal_perms[2]}m${octal_perms[2]}"
    octal_perms[3]="[4;3${octal_perms[3]}m${octal_perms[3]}"

    local kv_split=$'\t\e[0m'
    stat -c "[0;1mOwner:${kv_split}[1;93m%U[0m ([33m%u[0m)
[0;1mPermissions:${kv_split} ${(j..)perm_arr}[0m (${(j..)octal_perms}[0m)
[0;1mSize:${kv_split}[0;1;9${size_color}m$size_disp[0;3${size_color}m $label [0m(%b blocks)

[0;1mCreated:${kv_split}%w
[0;1mModified:${kv_split}%y
[0;1mAccessed:${kv_split}%x" $1
}

view::by-mime::path() {
    # get mime type and character encoding
    local file=${1-}
    local filecmd mime charset extension
    filecmd="$(file -bLi $file 2>/dev/null || :)"
    mime=${filecmd%%;*}
    charset=${filecmd##*charset=}
    extension=${file:e:l}

    case ${mime:=} in
    *'/directory')
        $lscmd $file
        ;;
    image/gif | video/*)
        ffmpeg -y -ss 0:00:00 -i "$i" -frames:v 1 -q:v 2 $TMPIMG &>/dev/null
        $chafacmd $TMPIMG
        exiftool $TMPIMG
        ;;
    # 'image/heic')
    #     exiftool $file
    #     ;;
    image/*)
        ffmpeg -y -i "$i" -q:v 2 "$TMPIMG" &>/dev/null
        $chafacmd $TMPIMG
        exiftool $TMPIMG
        ;;
    audio/*)
        # will expand later
        exiftool $file
        ;;
    application/pdf | text/pdf)
        pdftotext $file $TMPTXT
        cat $TMPTXT
        pdfinfo $file
        ;;
    *)
        case $extension in
        md)
            $mdcmd $file
            ;;
        odt | doc | docx | org | rtf | rst | ris | tsv | html | epub | latex | textile)
            [[ $extension == doc ]] && extension=docx # pandoc doesn't discriminate between them
            pandoc -f $extension -t markdown $file | $mdcmd
            ;;
        csv | xls | xlsx | ods)
            if [[ $extension == csv ]]; then
                pandoc -f csv -t plain $file
            elif ((${+commands[in2csv]})); then
                in2csv $file | pandoc -f csv -t plain -
            else
                print -P "%BNon-critical dependency 'in2csv' not found!%b"
                view::fallback::path $file
            fi
            ;;
        *)
            if [[ ${charset-} =~ (ascii|utf) ]]; then
                bat $file
            else
                view::fallback::path $file
            fi
            ;;
        esac
        ;;
    esac
}

# temporary files so this can convert and therefore view more formats
TMPIMG="${XDG_RUNTIME_DIR:-/tmp}/txtpreview-tmp.jpg"
TMPTXT="${XDG_RUNTIME_DIR:-/tmp}/txtpreview-tmp.txt"

for i in "$@"; do
    # clear out tmpfiles
    rm $TMPIMG $TMPTXT &>/dev/null || :

    # reset variables
    linkfile=${i:a}
    file=${i:A}

    # display file in lscolors
    print -n ${$($lscolorcmd $linkfile 2>/dev/null):-$linkfile}
    if [[ -L $linkfile ]]; then
        print " => ${$($lscolorcmd $file 2>/dev/null):-$file}"
    else
        print ''
    fi

    # display contents
    if [[ ! -r $file ]]; then
        # read-only
        view::fallback::path $file
    elif [[ -e $file ]]; then
        if [[ -p $file ]]; then
            # Reading lines out of a FIFO is dangerous
            view::fallback::path $file
        elif [[ ! -s $file ]]; then
            print "Empty file"
            view::fallback::path $file
        elif [[ -d $file ]]; then
            $lscmd $file
        elif [[ -S $file ]]; then
            lsof -t $file | while IFS=$'\n' read -r line; do
                pidstat -p $line
            done
        elif [[ -f $file ]]; then
            view::by-mime::path $file
        else
            view::fallback::path $file
        fi
    # broken symlinks are considered to not exist
    elif [[ -L $i ]]; then
        print 'Invalid link'
    else
        print 'Invalid path'
    fi
done
