#!/bin/sh
if [ $# -ne 1 ] \
|| [ ! -e "$1" ] \
|| [ "${1##*.}" != "mkv" ]; then
	echo "Error, Not an MKV?"
	echo ""Usage: ${0##*/} MKV_FILE_WITH_FAKE_PNG_HEADERS
	exit 1
fi

outname="$1".mkvnopng.mkv
sed 's/\x89PNG\r//g' "$1" > "$1".mkvnopng.mkv
echo "$outname"
