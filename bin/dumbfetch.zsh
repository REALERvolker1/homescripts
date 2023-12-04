#!/usr/bin/zsh

boxcolor="[0;38;5;$((RANDOM % 255))m"
cachefile="$XDG_RUNTIME_DIR/zsh-dumbfetch-$XDG_SESSION_ID.cache"
[[  "${1:-}" == '--no-cache' || ! -f $cachefile ]] && (
        print caching >&2
        # run command, then get all unique (u) values after "Use%". split into array with newlines (f)
        print ${(f)${(u)$(df -h -l -t btrfs -t xfs -t ext4 -t exfat --output=pcent)#Use%}}

        # The nvidia proprietary kernel module says its version in sysfs.
        if [[ -r /sys/module/nvidia/version ]]; then
            print "$(</sys/module/nvidia/version)"
        else
            print none
        fi

        # get the kernel version from /proc, filter it. should be same output as 'uname -r'
        kern="${${$(</proc/version)#*version }%% *}"
        # get version numbers
        typeset -a karr=("${kern%%-*}")

        matchstr="(XANMOD|ZEN|TKG|LQX|CACHY|CLEAR|NITRO|HARD|NEXT|GIT)"
        # First, get the kernel name, and convert it to uppercase ':u'. Then, find all the text that matches
        # the expanded matchstr at the end. Invert the match with (M) so we only get the text that matched.
        # Use another (M) match, but this time match from the beginning. Since the last time was from the end,
        # we will be left with the matched string.
        karr+=(${(M)${(M)${kern:u}%${~matchstr}*}##*${~matchstr}})

        [[ $kern == *(g14|rog)* ]] && karr+=(ROG) # Kernel with Asus-Linux patches
        [[ $kern == *lts* ]] && karr+=('(LTS)') # LTS kernel
        [[ $kern == *rt* ]] && karr+=('(RT)') # Realtime kernel -- deterministic scheduling
        # join kernel array with spaces
        print "${(j. .)karr}"
    ) >"$cachefile"

# this is less computationally expensive and more cross-platform than running procps uptime
typeset -a uptime
# read uptime file, everything up until the period
typeset -i upt="${$(</proc/uptime)%%.*}"
typeset -i hrs=$((upt / 3600))
typeset -i mins=$(((upt % 3600) / 60))
if ((hrs)) {
    uptime+=("${hrs} hr")
    ((hrs > 1)) && uptime+=(s)
    uptime+=(', ')
}
uptime+=("${mins} mn")
((mins > 1)) && uptime+=(s)

typeset -a props=(
    $((${SHLVL:-1000} - 1)) # shell level minux one, because this script is in its own shell
    "${(j..)uptime}" # join uptime array into a scalar with an empty string
    ${TERM:-Undefined} # current terminal, with fallback value
    "${(@f)$(<$cachefile)}" # load cachefile into array split by newlines.
)
# %%* matches each entire scalar element. The (N) flag substitutes each element for the length of its match.
# When ordered numberically (On), the first element is the length of the longest string. I take the first element.
typeset -i len=${${(OnN)props%%*}[1]}
# the sizes of my 'figlet' and my labels are known. However, the length of the props is dynamic.
# The (l:::) thingy pads an empty scalar variable on the left with a "$len" amount of box edge characters.
lenstr="${boxcolor}╭────────────────┬─────────────${(l:$len::─:)}╮[0m"

print $lenstr
print -f "${boxcolor}│[0;92m%s${boxcolor}│[0;9%-11s   [1m%-${len}s ${boxcolor}│[0m\n" \
    '        _ _     ' '4m  SHLVL'   "${props[1]}" \
    ' __   _| | | __ ' '5m 󰅐 Uptime'  "${props[2]}" \
    ' \ \ / / | |/ / ' '6m  Term'    "${props[3]}" \
    '  \ V /| |   <  ' '3m 󰋊 Disk'    "${props[4]}" \
    '   \_/ |_|_|\_\ ' '2m 󰾲 Nvidia'  "${props[5]}" \
    '                ' '1m  Kernel'  "${props[6]}"
# replace every topside box character with the corresponding bottomside character
print ${${${lenstr/╭/╰}/╮/╯}/┬/┴}
