#!/bin/sh
set -e
scriptname="${0##*/}"
if [ -z "$1" ]; then
	chim_mins="05 10 15 20 25 30 35 40 45 50 55"
else
	chim_mins="$1"
fi

sound="/usr/share/sounds/freedesktop/stereo/camera-shutter.oga"

echo "Chiming when minute unit is one of: $chim_mins"

while :; do
	cur_min=$(date +%M)
	set -- $chim_mins
	first_min="$1"
	while [ $# -ne 0 ]; do
		if [ "$1" = "$cur_min" ]; then
			next_min=$2
			[ -z "$next_min" ] && next_min=$first_min
			msg="Chimetime!!! $cur_min Next: $next_min"
			notify-send "$msg"
			echo "$msg"
			mpv --no-terminal --loop=1 "$sound"
			break
		fi
		shift
	done
	# sleep until next minute
	cursec=$(date +%-S)
	sleep $(( 60 - $cursec ))
done
