#!/bin/sh
if [ $# -lt 1 -o "$1" = "-h" ]; then
    echo "${0##*/} FILENAME [STARTTIME] [STOPTIME]"
    exit
fi

cd "$(dirname "$1")"
infile="$(basename "$1")"
ext="${infile##*.}"
outfile="${infile%.*}-clipped-$(date +%s).$ext"
starttime="$2"
stoptime="$3"

echo -n "]2;ffmpeg-clip.sh: $infile"

if [ -z "$starttime" ]; then 
	starttime="$(dialog --output-fd 1 --title "${0##*/}:$infile" --inputbox \
		"Enter start time ([??:]??:??)" 10 80 "00:00")" || exit 1
fi

if [ -z "$stoptime" ]; then
	stoptime="$(dialog --output-fd 1 --title "${0##*/}:$infile" --inputbox \
		"Enter stop time ([??:]??:??)\nEmpty for file end." 10 80 "")" || exit 1
fi

[ -n "$stoptime" ] && stoptime="-to $stoptime"

ffmpeg -hide_banner -i "$infile" -c copy -ss $starttime $stoptime "$outfile" 

