#!/usr/bin/bash
set -Eeuo pipefail

# Agent locations differ between distributions; exec keeps systemd tracking the agent.
for agent in \
    /usr/lib/mate-polkit/polkit-mate-authentication-agent-1 \
    /usr/libexec/xfce-polkit \
    /usr/lib/xfce-polkit/xfce-polkit \
    /usr/libexec/polkit-mate-authentication-agent-1 \
    /usr/libexec/polkit-gnome-authentication-agent-1 \
    /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 \
    /usr/libexec/lxqt-policykit-agent; do
    if [[ -x $agent ]]; then
        exec "$agent"
    fi
done
if command -v lxpolkit >/dev/null; then
    exec lxpolkit
fi
printf '%s\n' 'No suitable polkit agent found.' >&2
exit 1
