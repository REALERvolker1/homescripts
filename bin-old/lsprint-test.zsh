#!/usr/bin/env zsh
emulate -LR zsh -o glob_dots -o pipefail -o warncreateglobal -o err_exit
# it works I'm so happy aaaaaa

typeset -i MAX_HEIGHT=4
typeset -i MAX_WIDTH=$((COLUMNS - 4))

# typeset -a cwd=(*(^.) *(.))
typeset -a cwd=(*)
typeset -a cwd_fmt=(${(@f)$(lscolors $cwd)})
# typeset -i cwd_max_width=${${(OnN)cwd%%*}[1]}

typeset -a fmt_contents
typeset -a current_column current_column_fmt tmp_column
typeset -i current_height current_max_width current_padded_width tmp_width accumulated_width entry_count

tmparr_insert() {
    # max width plus 2 padding spaces
    current_max_width=${${(OnN)current_column%%*}[1]}
    current_padded_width=$((current_max_width + 2))
    local -i tmp_acc_width=$((accumulated_width + current_padded_width))

    if (( tmp_acc_width > MAX_WIDTH )) {
        # We're almost overflowing!
        return 1
    } else {
        accumulated_width+=current_padded_width
    }

    # format string with padding
    for i j in ${current_column:^current_column_fmt}; do
        entry_count+=1
        tmp_width=$((current_max_width - ${#i}))
        tmpstr=" $j${(l:$tmp_width:: :)null} "
        fmt_contents+=(${(q)tmpstr})
    done

    # Make sure the column is full, no holes in it
    if ((${#current_column[@]} < MAX_HEIGHT)) {
        local -i ccmhd=$((${MAX_HEIGHT} - ${#current_column[@]}))
        local str=" ${(l:$current_max_width:: :)null} "
        for ((i = 0; i < ccmhd; i++)); do
            fmt_contents+=(${(q)str})
        done
    }

    tmp_column=()
    current_column=()
    current_column_fmt=()
    current_height=0
}

null=''
typeset k v i j entry column tmpstr
for k v in ${cwd:^cwd_fmt}; do
    current_height+=1
    # current_column+=("${(q)k} ${(q)v}")
    current_column+=($k)
    current_column_fmt+=($v)
    if (( current_height >= MAX_HEIGHT )) {
        tmparr_insert || break
    }
done
((${#current_column} > 0)) && tmparr_insert || :

typeset -i colnum
typeset -A rows

typeset additional_space padding_spaces

# TODO: Make this able to print in configurable width, or with zero padding
declare -i pad_full=0
declare -i pad_width

if ((pad_full)) {
    pad_width=$MAX_WIDTH
    if (( accumulated_width < MAX_WIDTH )) {
        typeset -i is_content_odd is_width_odd padding_width
        is_content_odd=$((accumulated_width % 2))
        is_width_odd=$((MAX_WIDTH % 2))

        if (( is_content_odd != is_width_odd )) {
            additional_space=' '
            accumulated_width+=1
        }

        padding_width=$(((MAX_WIDTH - accumulated_width) / 2))
        padding_spaces="${(l:$padding_width:: :)}"

        # bottom_line+="${(l:MAX_WIDTH - accumulated_width::─:)}"
    }
} else {
    pad_width=$accumulated_width
}

typeset -i top_pad_width bottom_pad_width
typeset bottom_line top_line
typeset -i magic_pad_width=$((pad_width - 4))

typeset -i display_diff=$((${#cwd} - entry_count))
typeset -i display_diff_width
typeset display_diff_string display_diff_fmt_string

if (( display_diff > 0 )) {
    display_diff_string="┤ +$display_diff ├"
    display_diff_width=${#display_diff_string}
    if ((display_diff_width < magic_pad_width)) {
        display_diff_fmt_string="┤ +\e[1;92m$display_diff\e[0m ├"
    } else {
        # Should make it not show up at all if it is too big
        display_diff_width=0
    }
}

typeset cwd_display_fmt cwd_display
cwd_display=${(D)PWD}
typeset -i cwd_display_width=${#cwd_display}

if ((cwd_display_width > magic_pad_width)) {
    # Don't overflow it
    cwd_display="...${(l:$((pad_width - 7)):: :)cwd_display}"
}

cwd_color="\e[${${LS_COLORS##*:di=}%%:*}m"
cwd_display_fmt="┤ $cwd_color$cwd_display\e[0m ├"
top_pad_width=$((magic_pad_width - ${#cwd_display}))

top_line="${cwd_display_fmt}${(l:top_pad_width::─:)}"
bottom_line="${(l:$((pad_width - display_diff_width))::─:)}${display_diff_fmt_string}"

for column in ${(Q)fmt_contents}; do
    colnum+=1

    # print ${column}
    rows[$colnum]="${rows[$colnum]}${column}"
    if (( colnum == MAX_HEIGHT )) {
        colnum=0
    }
done


print "╭─${top_line}─╮"
for ((i=1; i<=${#rows[@]};i++)); do
    print "│ ${padding_spaces}${rows[$i]}${additional_space:-}${padding_spaces} │"
done
print "╰─${bottom_line}─╯"

# print -l -- ${(@kv)rows}

    # padded_strings+=("$v${(l:$((cwd_max_width - ${#k})):: :)}")

# typeset -a padded_strings
# ─
# for k v in ${cwd:^cwd_fmt}
#     padded_strings+=("$v${(l:$((cwd_max_width - ${#k})):: :)}")

# printf '│ %s%*s │\n' $v $((cwd_max_width - ${#k})) ''

# print -c -- $cwd_fmt #$padded_strings
