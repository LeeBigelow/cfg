#!/bin/sh
if [ -d "$1" ]; then
    srcd="$1"
    destd="Synced/"$(basename "$srcd")
else
    echo "Error, $1 not a directory."
    read -p "Done. Press ENTER." x
    exit
fi
numf=$(find "$srcd" -type f | wc -l)
echo "Source: $srcd"
echo "Destination: googledrive:$destd"
echo "Number of files to sync: $numf"
rclone sync "$srcd" googledrive:"$destd"/ \
    --one-file-system \
    --exclude-from "$HOME/.rsync_exclude" \
    --exclude-if-present ".ignore" \
    --delete-excluded \
    --checksum \
    --progress 
read -p "Done. Press ENTER." x
