#!/bin/bash
menucmd="fuzzel -p '⏻: ' -o eDP-1 -w 10 -l 5 -d" 
case "$1" in 
    "-tr") menucmd+=" -a top-right" ;;
    "-tl") menucmd+=" -a top-left" ;;
    "-br") menucmd+=" -a bottom-right" ;;
    "-bl") menucmd+=" -a bottom-left" ;;
esac
action=$(eval "$menucmd" << EOF
Suspend
Poweroff
Lock
Reboot
Log Out
EOF
)

logout_wm() {
	case "$XDG_CURRENT_DESKTOP" in
		*"sway"*) swaymsg exit ;;
		*"niri"*) niri msg action quit --skip-confirmation ;;
	esac
}

lock_wm() {
	if pgrep swayidle; then
		pkill -SIGUSR1 swayidle
	else
		exec swaylock -f -c 000000 -i ~/.wallpaper
	fi
}

case "$action" in
    "Poweroff") systemctl poweroff ;;
    "Lock") lock_wm ;;
    "Suspend") systemctl suspend ;;
    "Reboot") systemctl reboot ;;
    "Log Out") logout_wm ;;
esac
