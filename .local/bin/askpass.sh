#!/bin/sh
printf "$(zenity --password --title "$USER sudo" 2>/dev/null)"
