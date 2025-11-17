#!/bin/bash
if [ $# -gt 2 -o "$1" = "-h" ]; then
	echo "usage: ${0##*/} ROMPATH [CORE]"
	echo "Common cores: mesen-s, mame2003_plus, fbneo, mgba"
	echo
	exit
fi

corepath="$HOME/.config/retroarch/cores"
rom=$(realpath -e "$1")
if [ -z "$rom" ]; then
	echo "ERROR, ROM does not exist? ($rom)"
	exit
fi

if [ -n "$2" ]; then
	core="$2"
else
	rompath=$(dirname "$rom")
	case "${rompath##*/}" in
		fbneo) core="fbneo" ;;
		snes) core="mesen-s" ;;
		mame) core="mame2003_plus" ;;
		gba) core="mgba" ;;
		c64) core="vice_x64sc" ;;
		*) echo "ERROR, no core set for $rompath"; exit ;;
esac
fi
exec retroarch --libretro "$corepath"/"$core"_libretro.so "$rom"

#exec retroarch --fullscreen --config ~/.config/retroarch/retroarch.cfg --libretro "$corepath"/"$core"_libretro.so "$rom"

# for snap install:
#exec /snap/bin/retroarch --config ~/snap/retroarch/current/.config/retroarch/retroarch.cfg --libretro "$corepath"/"$core"_libretro.so "$rom"
#corepath="$HOME/snap/retroarch/current/.config/retroarch/cores"

