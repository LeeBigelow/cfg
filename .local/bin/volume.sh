#!/bin/bash
nidf=$HOME/.config/volume.nid
[ -e "$nidf" ] && last_nid=$(< $nidf)
[ -z "$last_nid" ] && last_nid=0

case "$1" in
    "up") 
        wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+
        ;;
    "down") 
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        ;;
    "mute")
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
    "mic-mute")
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        vol_str=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)
        notify-send -p -r $last_nid -t 3000 "Mic $vol_str" > $nidf
        exit
        ;;
    *) 
        echo "unknow request $1"
        exit
esac

vol_str=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
notify-send -p -r $last_nid -t 3000 "$vol_str" > $nidf
