#!/usr/bin/dash

HARDCODED_UNLOCKER="$HOME/.local/lib/hardcoded-keyring-unlocker"

if [ -x "$HARDCODED_UNLOCKER" ]; then
    if pgrep 'gnome-keyring-d' >/dev/null; then
        keyring_bool="$(
            busctl --user get-property 'org.gnome.keyring' \
                '/org/freedesktop/secrets/collection/login' \
                'org.freedesktop.Secret.Collection' \
                'Locked' | sed 's/^b //g'
        )"
        if [ "$keyring_bool" = 'false' ]; then
            exec $HARDCODED_UNLOCKER
        fi
    fi
fi

exec gnome-keyring-daemon -r
