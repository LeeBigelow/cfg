#!/bin/bash
sel_mode="$1"
outd="$HOME/Pictures/Screenshots"
mkdir -p $outd
cd -p $outd

# kill grim if alreadly running
pkill slurp
pkill grim


# Image to clipboard
case "$sel_mode" in
    "selected") 
        geom=$(slurp)
        [ -z "$geom" ] && exit
        ;;
    "focused") 
        geom=$(swaymsg -t get_tree | jq -r '.. | select(.type?) | select(.focused==true) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')
        [ -z "$geom" ] && exit
        ;;
    "all") geom=""
        ;;
    *) 
        echo "Usage: ${0##*/} [ all | selected | focused ]"
        exit ;;
esac

fname=$(date +"${sel_mode}_%Y%m%d_%Hh%Mm%Ss.png")
fname=$(ls "$outd" | fuzzel -d -w 30 --search="$fname")
if [ -z "$fname" ]; then
    exit
elif [[ "${fname##*.}" != "png" ]]; then
    fname="$fname.png"
fi
fname="$outd/$fname"

if [ -n "$geom" ]; then
    grim -g "$geom" "$fname" && pqiv "$fname"
else
    grim "$fname" && pqiv "$fname"
fi

