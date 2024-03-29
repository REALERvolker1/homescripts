#!/usr/bin/zsh

codecmd=''
typeset -a codeargs=()
me="$0"

if [[ ${1:-} == '--flatpak' ]]; then
    shift 1
elif [[ -x ${VLK_VSC:-null} ]]; then
    codecmd="$VLK_VSC"
else
    # change order to change preference
    () {
        local i j
        foreach i (codium code) {
            for j in ${${${(@)path}//%/\/$i}//$me}; do
                if [[ -x $j ]]; then
                    codecmd="$j"
                    return
                fi
            done
            # [[ -x $codecmd ]] && break
        }
    }
fi

noinst() {
    notify-send -a "${me##*/}" 'Error' "Could not find VSCodium installation"
    echo 'Error,' "Could not find VSCodium installation"
    exit 1
}
# code-oss doesn't work with wayland
[[ ${codecmd:-} == *codium && -n ${WAYLAND_DISPLAY:-} ]] && codeargs+=(--enable-features=UseOzonePlatform --ozone-platform=wayland)

if [[ ! -x $codecmd ]]; then
    command -v flatpak &>/dev/null || noinst
    flatpak_path=''
    () {
        local i
        local flatpaks
        flatpaks="$(flatpak list --app --columns=application)"
        foreach i ('com.vscodium.codium' 'com.visualstudio.code' 'com.visualstudio.code-oss' eee); do
            if [[ "${flatpaks[*]}" == *"$i"* ]]; then
                flatpak_path="$i"
                return
            fi
        done
    }
    if [[ -n $flatpak_path ]]; then
        codecmd=flatpak
        codeargs=(run "$flatpak_path" "${(@)codeargs}")
    else
        noinst
    fi
fi

codeargs+=("$@")

echo "$codecmd" "${(@)codeargs}"
exec "$codecmd" "${(@)codeargs}"

# for i in ${${(@)path}//$0}; do
# done

# if [ -x "${VLK_VSC:-null}" ]; then
#     codium_path="${VLK_VSC:-null}"
# else
#     codium_path="$(
#         IFS=':'
#         for i in $PATH; do
#             for j in $editors; do
#                 i_path="$i/$j"
#                 [ "$i_path" = "$0" ] && continue
#                 if [ -x "$i_path" ]; then
#                     echo "$i_path"
#                     break
#                 fi
#             done
#         done
#     )"
# fi

# [ -n "${WAYLAND_DISPLAY:-}" ] && ozonewayland='--enable-features=UseOzonePlatform --ozone-platform=wayland '
# if [ -n "${codium_path:-}" ]; then
#     echo "Launching $codium_path"
#     exec $codium_path ${ozonewayland}"$@"
# elif [ -f "$flatpak_path" ]; then
#     exec flatpak run com.vscodium.codium ${ozonewayland}"$@"
# else
#     notify-send -a "${0##*/}" 'Error' "Could not find VSCodium installation"
# fi
