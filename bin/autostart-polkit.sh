#!/usr/bin/dash

for i in \
    '/usr/lib/mate-polkit/polkit-mate-authentication-agent-1' \
    '/usr/libexec/xfce-polkit' \
    '/usr/lib/xfce-polkit/xfce-polkit' \
    '/usr/libexec/polkit-mate-authentication-agent-1' \
    '/usr/libexec/polkit-gnome-authentication-agent-1' \
    '/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1' \
    '/usr/libexec/lxqt-policykit-agent' \
    'lxpolkit'; do
    [ -x "$i" ] && exec "$i"
done

echo "$0 -- no suitable polkit agent found"
