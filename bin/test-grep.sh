#!/usr/bin/dash

lolpath="/home/vlk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/sbin:/home/vlk/bin:/home/vlk/.local/bin:/home/vlk/.local/share/cargo/bin:/home/vlk/.local/share/go/bin:/home/vlk/.local/share/pnpm:/home/vlk/.local/share/python/bin:/var/lib/flatpak/exports/bin:/usr/lib64/ccache:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl"
lolpath="$HOME/bin:\
$HOME/.local/bin:\
${CARGO_HOME:-C}/bin:\
${GOPATH:-G}/bin:\
${BUN_INSTALL:-B}/bin:\
${PNPM_HOME:-P}:\
${PYTHONUSERBASE:-P}/bin:\
/var/lib/flatpak/exports/bin:\
${lolpath}"
unsetrp='true'
if ! command -v realpath >/dev/null 2>&1; then
    if command -v readlink >/dev/null 2>&1; then
        realpath() {
            readlink "$@"
        }
    else
        realpath() {
            [ "${1:-}" = '-qe' ] && shift 1
            echo "$@"
        }
    fi
    unsetrp='unset -f realpath'
fi
newpath=''
oldifs="$IFS"
IFS=':'
for i in $lolpath; do
    [ ! -e "$i" ] && continue
    [ -h "$i" ] && i="$(realpath -qe "$i")"
    case ":${newpath}:" in
    *:"$i":*)
        continue
        ;;
    *)
        if [ -z "$newpath" ]; then
            newpath="$i"
        else
            newpath="$newpath:$i"
        fi
        ;;
    esac
done
echo "$newpath"

IFS="$oldifs"
$unsetrp
unset lolpath unsetrp oldifs newpath


exit 0

PATHMUNGE_PATH="$PATH" cr "$HOME/bin" "$HOME/.local/bin" "${CARGO_HOME:-CARGO_HOME}/bin" "${GOPATH:-GOPATH}/bin" "${BUN_INSTALL:-BUN_INSTALL}/bin" "${PNPM_HOME:-PNPM_HOME}" "${PYTHONUSERBASE:-PYTHONUSERBASE}/bin" '/var/lib/flatpak/exports/bin'
