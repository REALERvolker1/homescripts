#!/usr/bin/bash
set -euo pipefail
IFS=$'\n\t'

panic() {
    printf '%s\n' "$@" >&2
    exit 1
}

for i in 'jq' 'fc-match'; do
    command -v "$i" &>/dev/null || panic "Error, failed to find dependency '$i'"
done

###
# Get available themes
###

declare -A pth

pth[cfg]="${XDG_CONFIG_HOME:-$HOME/.config}"
pth[settings]="${pth[cfg]}/appearance.json"

# settingsfiles
pth[gtk2]="${GTK2_RC_FILES:-$HOME/.gtkrc}"
pth[gtk3]="${pth[cfg]}/gtk-3.0/settings.ini"
pth[gtk4]="${pth[cfg]}/gtk-4.0/settings.ini"
pth[fc]="${pth[cfg]}/fontconfig/fonts.conf"
pth[cursor]="${XDG_DATA_HOME:-$HOME/.local/share}/icons/default/index.theme"

for i in "${pth[@]}"; do
    [ -f "$i" ] && continue
    mkdir -p "${i%/*}"
done

declare -a gtk2_themes
declare -a gtk3_themes
declare -a gtk4_themes
declare -a icon_themes
declare -a cursor_themes

oldifs="$IFS"
IFS=':'
for i in $XDG_DATA_DIRS; do
    if [ -d "$i/themes" ]; then
        for j in "$i/themes/"*; do
            [ -d "$j/gtk-2.0" ] && gtk2_themes+=("$j")
            [ ! -f "$j/index.theme" ] && continue # gtk2 does not require this
            [ -d "$j/gtk-3.0" ] && gtk3_themes+=("$j")
            [ -d "$j/gtk-4.0" ] && gtk4_themes+=("$j")
        done
    fi
    if [ -d "$i/icons" ]; then
        for j in "$i/icons/"*; do
            [ ! -f "$j/index.theme" ] && continue
            [ -d "$j/cursors" ] && cursor_themes+=("$j")
            [[ "$j" == *'hicolor' ]] && continue # fallback icons
            for k in "$j/"*; do
                if [ -d "$k" ]; then
                    icon_themes+=("$j")
                    break
                fi
            done
        done
    fi
done
IFS="$oldifs"

###
# Read settings file
###
echo "reading settings file..." >&2

settings_file="$(cat "${pth[settings]}")"
ecset() {
    echo "$settings_file" | jq -r "$@"
}

# cursor
declare -A cursor
cursor[theme]="$(ecset '.cursor.theme')"
cursor[size]="$(ecset '.cursor.size')"

# font
declare -A font
derive_font() {
    while read -r i; do
        if fc-match -s "$i" --format='%{family}\n' | grep -q "$i"; then
            echo "$i"
            break
        fi
    done
}

font[sans]="$(ecset '.fonts."sans-serif" | .[]' | derive_font)"
font[serif]="$(ecset '.fonts."serif" | .[]' | derive_font)"
font[mono]="$(ecset '.fonts."monospace" | .[]' | derive_font)"

declare -a universal_fonts
for i in $(ecset '.fonts."universal" | .[]'); do
    universal_fonts+=("$(echo "$i" | derive_font)")
done

font[size]="$(ecset '.fonts."size"')"

font[xft_aa]="$(ecset '.fonts.rendering."antialias"')"
font[xft_hint]="$(ecset '.fonts.rendering."hinting"')"
font[xft_hintstyle]="$(ecset '.fonts.rendering."hintstyle"')"
font[xft_rgba]="$(ecset '.fonts.rendering."rgba"')"

# gtk
declare -A gtk2
declare -A gtk3
declare -A gtk4

for i in $(ecset '.gtk | keys[]'); do
    val="$(ecset ".gtk.\"$i\".value")"
    for j in $(ecset ".gtk.\"$i\".\"versions\" | .[]"); do
        declare "gtk${j}[$i]=$val"
    done
    override="$(ecset ".gtk.\"$i\".override")"
    if [ "$override" != 'null' ]; then
        val="$(ecset ".gtk.\"$i\".override.value")"
        for j in $(ecset ".gtk.\"$i\".override.\"versions\" | .[]"); do
            declare "gtk${j}[$i]=$val"
        done
    fi
done

for i in gtk{2,3,4}; do
    declare "${i}[font-name]=sans-serif ${font[size]}"
    declare "${i}[xft-antialias]=${font[xft_aa]}"
    declare "${i}[xft-hinting]=${font[xft_hint]}"
    declare "${i}[xft-hintstyle]=${font[xft_hintstyle]}"
    declare "${i}[xft-rgba]=${font[xft_rgba]}"
    declare "${i}[cursor-theme-name]=${cursor[theme]}"
    declare "${i}[cursor-theme-size]=${cursor[size]}"
done

###
# Set settings
###

# gtk2
(
    for i in "${!gtk2[@]}"; do
        i_str="${gtk2[$i]}"
        case "${i_str:-}" in
        'GTK_'*)
            :
            ;;
        '' | *[!0-9]*)
            i_str="\"${gtk2[$i]}\""
            ;;
        esac
        printf "gtk-%s=%s\n" "$i" "$i_str"
    done
) >"${pth[gtk2]}"

# gtk3
(
    echo "[Settings]"
    for i in "${!gtk3[@]}"; do
        printf "gtk-%s=%s\n" "$i" "${gtk3[$i]}"
    done
) >"${pth[gtk3]}"

# gtk4
(
    echo "[Settings]"
    for i in "${!gtk4[@]}"; do
        printf "gtk-%s=%s\n" "$i" "${gtk4[$i]}"
    done
) >"${pth[gtk4]}"

# fontconfig
(
    if ((${font[xft_aa]} == 1)); then
        antialiasing=true
    else
        antialiasing=false
    fi
    if ((${font[xft_hint]} == 1)); then
        hinting=true
    else
        hinting=false
    fi
    printf '%s\n' \
        '<?xml version="1.0"?>' \
        '<!DOCTYPE fontconfig SYSTEM "fonts.dtd">' \
        '<fontconfig>' \
        '<match target="font">' \
        '<edit name="antialias" mode="assign">' \
        "<bool>${antialiasing}</bool>" \
        '</edit>' \
        '<edit name="hinting" mode="assign">' \
        "<bool>${hinting}</bool>" \
        '</edit>' \
        '<edit name="hintstyle" mode="assign">' \
        "<const>${font[xft_hintstyle]}</const>" \
        '</edit>' \
        '<edit name="rgba" mode="assign">' \
        "<const>${font[xft_rgba]}</const>" \
        '</edit>' \
        '</match>' \
        '<alias>' \
        '<family>sans-serif</family>' \
        '<prefer>'

    printf '<family>%s</family>\n' \
        "${font[sans]}" \
        "${universal_fonts[@]}"

    printf '%s\n' \
        '</prefer>' \
        '</alias>' \
        '<alias>' \
        '<family>serif</family>' \
        '<prefer>'

    printf '<family>%s</family>\n' \
        "${font[serif]}" \
        "${universal_fonts[@]}"

    printf '%s\n' \
        '</prefer>' \
        '</alias>' \
        '<alias>' \
        '<family>monospace</family>' \
        '<prefer>'

    printf '<family>%s</family>\n' \
        "${font[mono]}" \
        "${universal_fonts[@]}"

    printf '%s\n' \
        '</prefer>' \
        '</alias>' \
        '</fontconfig>'

) >"${pth[fc]}"

# cursor theme
(
    printf '%s\n' \
        '[Icon Theme]' \
        "Inherits=${cursor[theme]}"
) >"${pth[cursor]}"

# 
