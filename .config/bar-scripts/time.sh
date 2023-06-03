#!/usr/bin/dash

case "$(date +'%-I')" in
    1) hours=󱑋 ;;
    2) hours=󱑌 ;;
    3) hours=󱑍 ;;
    4) hours=󱑎 ;;
    5) hours=󱑏 ;;
    6) hours=󱑐 ;;
    7) hours=󱑑 ;;
    8) hours=󱑒 ;;
    9) hours=󱑓 ;;
    10) hours=󱑔 ;;
    11) hours=󱑕 ;;
    12) hours=󱑖 ;;
    *) hours=󰗎 ;;
esac
date +"$hours %a, %-m/%-d %-I:%M %P"
