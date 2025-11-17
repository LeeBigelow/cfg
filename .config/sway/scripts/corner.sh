#!/bin/bash

usage() {
	cat <<EOF
Usage: "$0" [-m|-s] c|tl|tr|bl|br
	-m  Resize medium (50%) then corner
	-s  Resize small (33%) then corner
    Choose one of:
		c   Center
		tl  Top Left
		tr  Top Right
		bl  Bottom Left
        br  Bottom Right
EOF
	exit
}

read mon_w mon_h < <(swaymsg -t get_workspaces | jq -r '
	.. 
	| select(.type?)
	| select(.type == "workspace")
	| select(.focused?)
	| [.rect.width, .rect.height]
	| join(" ")')

current_win() {
	swaymsg -t get_tree | jq -r '
		..
		| objects
		| select(.type?)
		| select(.focused == true)'
}

if [[ "$(current_win | jq -r '.floating')" == *"off" ]]; then
	swaymsg floating enable
	sleep 0.1
fi

resize_small() {
	swaymsg resize set width 33 ppt height 33 ppt
	sleep 0.1
}

resize_medium() {
	swaymsg resize set width 50 ppt height 50 ppt
	sleep 0.1
}

case "$1" in
	"-s") resize_small; shift ;;
	"-m") resize_medium; shift ;;
	"-"*) usage ;;
esac


read win_w win_h < <(current_win | jq -r '[.rect.width, .rect.height] | join(" ")')

case "$1" in
	c) swaymsg move position center ;;
	tl) swaymsg move position "0" px "0" px ;;
	tr) swaymsg move position "$(( mon_w - win_w ))" px 0 px ;;
	bl) swaymsg move position "0" px "$(( mon_h - win_h ))" px ;;
	br) swaymsg move position "$(( mon_w - win_w ))" px "$(( mon_h - win_h ))" px ;;
	*) usage ;;
esac
