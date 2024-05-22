#!/usr/bin/env bash
# shellcheck shell=bash disable=2209
# a script by vlk that searches for dnf packages and installs them
set -euo pipefail
IFS=$'\n\t'
OLDIFS="$IFS"

# This is so that I have complete control over formatting
if [[ ${1:-} == '--fzf-list-info' ]]; then
    shift 1
    package_name="${*%%$'\t'*}"
    echo "Info for $package_name"
    dnf info -C "$package_name"
    exit $?
fi

# useful functions
_panic() {
    printf '[0m%s[0m\n' "$@" >&2
    exit 1
}

_prompt() {
    local answer
    printf '%s\n' "$@"
    read -r -p "[y/N] > " answer
    if [[ ${answer:-} == y ]]; then
        return 0
    else
        return 1
    fi
}

# dependency check
declare -a faildeps=()
for i in dnf fzf grep sed realpath; do
    command -v "$i" &>/dev/null || faildeps+=("$i")
done
((${#faildeps[@]})) && _panic "Error, missing dependencies:" "${faildeps[@]}"
[[ -z "${XDG_RUNTIME_DIR:-}" ]] && _panic "Error, \$XDG_RUNTIME_DIR is not set!"

# packages I will likely never install unless I specifically need, and that clutter my search results
declare -a default_start_spam=(
    abrt tesseract texlive 'python[0-9]' python rust ruby php perl ocaml 'mingw[36][24]' langpacks lua 'ghc[0-9][^-]+'
    ghc 'f[0-9][0-9]' emacs R golang compat-golang glibc-langpack globus hunspell hyphen ibus java 'kf[56]' 'qt[56]'
    qt libreoffice maven opensips pcp avogadro2 boost erlang fedora flexmark gambas3 gap gcc gimp-help gnome-shell
    'google-noto' guayadeque 'kde-[il]1[80]n' lomiri man-pages mathjax mathgl mono mythes mythtv nagios nbdkit netcdf
    nodejs nordugrid obs-service obs-build octave plexus plplot postgresql qemu root rubygem sblim shotcut-langpack
    sugar switchboard telepathy tex uwsgi vim wingpanel xstatic default-fonts libvirt proj-data
)

declare -a spam_arr=(
    '-debuginfo\.'
    '-debugsource\.'
    'maven-plugin'
)

# set IFS for array var splitting
IFS='|'

for i in "${default_start_spam[@]}"; do
    spam_arr+=("^${i}-")
done

# separate default config and regular config so I can print it out intact
declare -A default_config=(
    [querytype]=available
    [arch]='noarch|x86_64'
    [refresh]=0
    [spam]="(${spam_arr[*]})"
    [show_spam]=0
)
IFS="$OLDIFS"

# ripgrep is much faster than regular grep and supports pcre2
if command -v rg &>/dev/null; then
    default_config[grep]=rg
else
    echo "Ripgrep not found, falling back to (slower) regular grep" >&2
    default_config[grep]=grep
fi

declare -A config
for i in "${!default_config[@]}"; do
    config[$i]="${default_config[$i]}"
done

declare -a fzf_args=(--multi --ansi --preview="$0 --fzf-list-info {}")

declare -a fzf_query=()

for i in "$@"; do
    i_val="${i#*=}"
    case "${i:=}" in
    --all | -a)
        config[querytype]=all
        config[show_spam]=1
        ;;
    --available | -av)
        config[querytype]=available
        ;;
    --installed | -i)
        config[querytype]=installed
        ;;
    --updates | --upgrades | -u)
        config[querytype]=upgrades
        ;;
    --autoremove | -ar)
        config[querytype]=autoremove
        ;;
    --recent | -r)
        config[querytype]=recent
        ;;
    --refresh)
        config[refresh]=1
        ;;
    --spam=* | --spam | -s=* | -s)
        if [[ -z "${i_val:-}" || $i == "${i_val:-}" ]]; then
            config[show_spam]=1
        else
            config[spam]="${i_val:-}"
        fi
        config[refresh]=1
        ;;
    --grepcmd=*)
        config[grep]="$i_val"
        ;;
    --arches | --arches=*)
        config[arch]="$i_val"
        [[ -z "${i_val:-}" || $i == "${i_val:-}" ]] && config[arch]='[^ \.]*'
        config[refresh]=1
        ;;
    -*)
        echo "
Error, invalid arg passed! '$i'

Valid arguments include:
--all (-a)          show all packages (including spam)
--available (-av)   show only available packages (default)
--installed (-i)    show only installed packages
--upgrades (-u)     show only upgrades packages
    --updates       show only upgrades packages
--autoremove (-ar)  show only autoremove packages
--recent (-r)       show only recently changed packages

--refresh           Refresh dnf cache

--grepcmd=grepcmd   Override default grep command
This must support pcre2 regexp. By default ${0##*/} tries to use
ripgrep (rg), and falls back to regular grep. It expects to fall back
to GNU grep.

--arches=ARCH1|ARCH2|ARCH3
Pipe-separated list of architectures to show. Leave empty (--arches='' | --arches) to show all.
Recommended: use the command \`dnf list --available | grep -oP '^[^ ]+\.\K[^ \.]+' | sort | uniq\`
This shows all the different architectures to choose from
Anything other than the defaults cannot be cached.

--spam='^(pkgname1|pkgname2)-' (-s='')
Excludes packages that could be considered spam. Leave blank (--spam or --spam='') to show all
Takes a pcre2 regex string
Run using \`... | grep -v '\$spam'\`

All other args are passed as queries to fzf

Default config:
"
        for j in "${!default_config[@]}"; do
            printf "[%s] = '%s'\n" "$j" "${default_config[$j]}"
        done
        exit 2
        ;;
    *)
        fzf_query+=("$i")
        ;;
    esac
done
# search for packages with extra args
if ((${#fzf_query[@]})); then
    IFS=' '
    fzf_args+=(-q "${fzf_query[*]}")
    IFS="$OLDIFS"
fi

fzf_args+=("--header=Showing ${config[querytype]^^}. Press TAB to select multiple")

# dnf options to get the best stuff
declare -a dnf_opts=(--skip-broken --allowerasing --best)

declare -A arch_colortable=(
    [noarch]=93
    [x86_64]=92
    [i686]=91
    [i386]=31
    [src]=90
    [aarch64]=94
    [armv6hl]=35
    [armv7hl]=95
)

declare -A repo_colortable=(
    [charm]=95
    [terra]=94
    [commandline]=90
    [fedora]=34
    [updates]=92
    ['fedora-cisco-openh264']=34
    ['rpmfusion-free']=32
    ['rpmfusion-free-updates']=92
    ['rpmfusion-free-tainted']=93
    ['rpmfusion-nonfree']=31
    ['rpmfusion-nonfree-updates']=91
    ['rpmfusion-nonfree-tainted']=93
    # ['copr:[^ ]*']=96
)

declare -A name_part_colortable_256=(
    ['-devel']=244
    ['compat']=244
    ['-debuginfo']=244
    ['-debugsource']=244
    ['git']=93
    ['^lib']=21
    ['^xorg[^-]*-']=44
    ['x11']=44
)

# pretty-format the output
declare -a sedarr=(
    's/\t([^\t]+)\s*$/\t[92m\1[0m/g'               # remove all the blanks from the ends
    "s/\t([^\t]*)\.fc$(rpm -E '%fedora')\t/\t\1\t/g" # remove '.fc39' from the end of the package version string
)

declare -a namesedarr=()

for i in "${!name_part_colortable_256[@]}"; do
    sedarr+=("s/^([^\t]*)($i)([^\t]*)\t/\1[38;5;${name_part_colortable_256[$i]}m\2[0m\3\t/g")
    namesedarr+=("s/($i)/[38;5;${name_part_colortable_256[$i]}m\1[0m/g")
done
for i in "${!arch_colortable[@]}"; do
    sedarr+=("s/($i)\t/[${arch_colortable[$i]}m\1[0m\t[2m/g")
    namesedarr+=("s/($i)\$/[${arch_colortable[$i]}m\1[0m/g")
done
for i in "${!repo_colortable[@]}"; do
    sedarr+=("s/\t([^\t]*)($i)[^\t ]*/[0m\t\1[${repo_colortable[$i]}m\2[0m/g")
done
pkgsedstr="${sedarr[*]}"

#

echo "Refreshing..."
selection="$(
    # skip spam packages
    if ((config[show_spam])); then
        grepstr='^$'
    else
        grepstr="${config[spam]}"

    fi

    # save into a variable so the fzf window isn't just open empty for a long time
    dnf_packages="$(dnf list -C "${dnf_opts[@]}" --"${config[querytype]}" | tr -s '[:blank:]' '\t' | ${config[grep]} -P "^[^ ]+\.(${config[arch]})" | sed -E "$pkgsedstr" | ${config[grep]} -Pv "$grepstr")"
    fzf "${fzf_args[@]}" <<<"$dnf_packages"
)"

#

[[ -z "${selection:-}" ]] && _panic "No packages selected!"

declare -a install_pkgs=()
declare -a remove_pkgs=()

# I noticed that if a package is installed, the name of its repo is prefixed with a '@', and if it is not installed, there is no prefix.
while read -r i; do
    if [[ "${i##*$'\t'}" == '@'* ]]; then
        remove_pkgs+=("${i%%$'\t'*}")
    else
        install_pkgs+=("${i%%$'\t'*}")
    fi
done <<<"$selection"

declare -i INSTALL="${#install_pkgs[@]}"
declare -i REMOVE="${#remove_pkgs[@]}"

declare -a dnf_errors=()

namesedstr="${namesedarr[*]}"

if ((INSTALL)); then
    install_pkgs_str="$(printf '%s\n' '' "${install_pkgs[@]}" '' | sed -E "$namesedstr; s/^(.)/[1;92m\[\+\][0m \1/g")"
    echo -e "\e[1m=== Installing $INSTALL packages ===\e[0m\n$install_pkgs_str" # [0m \e[1;92m[+]\e[0;1m
    if _prompt "Want to install these packages?"; then
        sudo dnf install "${dnf_opts[@]}" "${install_pkgs[@]}" || dnf_errors+=("install packages" "${install_pkgs[@]}")
    fi
fi

if ((REMOVE)); then
    remove_pkgs_str="$(printf '%s\n' '' "${remove_pkgs[@]}" '' | sed -E "$namesedstr; s/^(.)/[1;91m\[\-\][0m \1/g")"
    echo -e "\e[1m=== Removing $REMOVE packages ===\e[0m\n$remove_pkgs_str"
    if _prompt "Want to remove these packages?"; then
        sudo dnf remove "${dnf_opts[@]}" "${remove_pkgs[@]}" || dnf_errors+=("remove packages" "${remove_pkgs[@]}")
    fi
fi

if ((${#dnf_errors[@]})); then
    _panic "Errors occured during transaction!" "${dnf_errors[@]}"
else
    echo "Done!"
fi
