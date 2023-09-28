((COLUMNS > 55)) && {
    dumbfetch
    command -v fortune &>/dev/null && fortune -a -s | (
        if command -v lolcrab &>/dev/null; then
            lolcrab
        elif command -v lolcat &>/dev/null; then
            lolcat
        else
            tee
        fi
    )
    lsdiff
}
