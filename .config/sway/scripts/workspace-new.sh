#!/bin/bash
# 10 is the reserved for the monitor, so remove from list
num=$(swaymsg -t get_workspaces | jq '.[] | .num'| sed -e '/10/d' | sort -n | tail -n 1)
let num+=1
(( num == 10 )) && let num+=1
case "$1" in
	open) 
		swaymsg workspace number $num 
		;;
	move) 
		swaymsg move container to workspace number $num 
		swaymsg workspace $num 
		;;
	send) 
		swaymsg move container to workspace number $num 
		;;
	*) 
		echo "${0##*/} <open|move>" 
		echo "open a new empty workspace or"
		echo "move current container to new workspace"
		;;
esac

