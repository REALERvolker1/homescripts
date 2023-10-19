#!/bin/bash

# required
unset name githubrepo payload decompresscmd cmds links

# name of the pkg
name='thorium'
# author/project name of the github repo
githubrepo='Alex313031/thorium'
# the output archive file
payload='thorium-browser*amd64.zip'
# the decompression command
decompresscmd='unzip -o'
# commands needed to install package, run in the installation directory
cmds="sed -i 's|^Exec=\./|Exec=|g ; s|^Icon=.*|Icon=thorium|' ./thorium-portable.desktop
for i in \$(pwd)/product_logo_*.png; do
i_int=\"\${i%.*}\"; i_int=\"\${i_int##*_}\"
i_folder=\"$XDG_DATA_HOME/icons/hicolor/\${i_int}x\${i_int}/apps\"
mkdir -p \"\$i_folder\"
ln -sf \"\$i\" \"\${i_folder}/thorium.png\"
done"
# files to install (symlink target*destination/)
declare -a links=(
    "thorium*$HOME/.local/bin/thorium-browser"
    "thorium-portable.desktop*${XDG_DATA_HOME:=$HOME/.local/share}/applications/"
)
