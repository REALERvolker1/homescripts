#!/usr/bin/dash

output='󰧠'
class=none

case "${info:=$(curl -sf 'v2n.wttr.in?format=%c%t' | sed -E -e 's/F| //g' -e 's/\+/ /g')}" in
*Sorry*)
    output='󰧠'
    class=sorry
    ;;
Unknown*)
    output='󰨹'
    class=unknown
    ;;
*)
    output="${info:-󰅤}"
    class=normal
    ;;
esac

case "${1:-}" in
--waybar)
    echo "{\"text\": \"$output\", \"tooltip\": \"Weather: $output\", \"class\": \"$class\"}"
    ;;

*)
    echo "$output"
    ;;
esac
#   echo ' !' ;;  echo ' ?' ;; *)  ;; esac
