#!/bin/sh
if [ -d "$1" -a -d "$2" ]; then
    srcd="$1"
    destd="$2"
else
    echo "USAGE: ${0##*/} SOURCE_DIR DEST_DIR"
    echo "Error, $1 or $2 not a directory."
    read -p "Done. Press ENTER."
    exit
fi

echo "Source: $srcd"
echo "Destination: $destd"
rsync \
	--verbose \
    --archive \
    --one-file-system \
    --delete \
    --delete-excluded \
    --cvs-exclude \
    --exclude-from="$HOME/.rsync_exclude" \
    "$srcd" "$destd"

