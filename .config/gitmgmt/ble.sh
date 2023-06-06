#!/usr/bin/bash
source gitmgmt.sh --source

clone_func "https://github.com/akinomyoga/ble.sh"
change_cwd

make

echo ". '$PWD/out/ble.sh' --noattach --rcfile '$BDOTDIR/blerc'" > "$BDOTDIR/launch-ble.sh"
