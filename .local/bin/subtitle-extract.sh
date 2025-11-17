#!/bin/sh
vidpath="$1"
subs=$(ffprobe -v 8 -hide_banner \
	-select_streams s \
    -show_entries "stream=index:stream=codec_name:stream_tags=language" \
    -of "csv=p=0" "$vidpath")

[ -z "$subs" ] && echo "No subs found" && exit
echo "Found:"
echo "$subs"
# convert list of idx[,lang] entries to one long string for zenity

items=""
# Index,Codec,Lang
for s in $subs; do
	I="${s%%,*}"
	C="${s%,*}"
	C="${C#*,}"
    L="${s##*,}"
    [ -z "$L" ] && L="UND"
    items="$items $I $C $L "
done

set -- $items
while [  $# -gt 0 ]; do
    idx=$1
    codec=$2
    lang=$3
    shift m
	case $codec in
		webvtt) subext="vtt" ;;
		ass) subext="ass" ;;
		*) subext="srt" ;;
	esac
    subfile="${vidpath%.???}_${idx}_${lang}.$subext"
    ffmpeg -hide_banner -v 8 -y -i "$vidpath" -map 0:$idx "$subfile" \
	   && extracted="$extracted\n$subfile"
done

echo "Extracted: $extracted"

