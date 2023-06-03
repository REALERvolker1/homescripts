#!/bin/bash

## disable "expressions don't expand in single quotes" error
# shellcheck disable=SC2016

ensure_startx () {
    sed '
        s|xserverauthfile=$HOME|xserverauthfile=$XDG_RUNTIME_DIR|
        s|XAUTHORITY=$HOME|XAUTHORITY=$XDG_RUNTIME_DIR|

        s|userclientrc=$HOME/.xinitrc|userclientrc=$XDG_CONFIG_HOME/X11/xinitrc|
        s|userserverrc=$HOME/.xserverrc|userserverrc=$XDG_CONFIG_HOME/X11/xserverrc|
        ' '/usr/bin/startx' > "$HOME/bin/startx" && chmod +x "$HOME/bin/startx"
}

ensure_startx
