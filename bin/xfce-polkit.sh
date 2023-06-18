#!/bin/sh

case "${CURRENT_DISTRO:-}" in
    'Arch')
        pkpath='/usr/lib/xfce-polkit/xfce-polkit'
        errmsg="Error, please install 'xfce-polkit' from the AUR!"
        ;;
    'Fedora')
        pkpath='/usr/libexec/xfce-polkit'
        errmsg="Error, please install 'xfce-policykit' with DNF"
        ;;
    *)
        echo "Error, \$CURRENT_DISTRO value '$CURRENT_DISTRO' is unsupported!"
        exit 1
        ;;
esac

if [ ! -x "$pkpath" ]; then
    echo "$errmsg"
    exit 1
fi

exec $pkpath

