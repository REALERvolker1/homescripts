#!/usr/bin/zsh

if command -v fortune &>/dev/null && command -v lolcat &>/dev/null; then
    fortune -a -s | lolcat
fi
