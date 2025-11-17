#!/bin/bash
set -e
cd $HOME

# backup list of "other" code, not their full repos
otherfile="Code/Mine/other.txt"
ls -d Code/Other/* > "$otherfile"
grep "url" Code/Other/*/.git/config >> "$otherfile"
grep "^url" Code/Other/*/PKGBUILD >> "$otherfile"
sort -o "$otherfile" "$otherfile"

# package list
pacman -Qqe > ~/Documents/package-list.txt

# back up .conf, if small enough
sizelimit=2000000
tarfile="$(tar-backup-dir.sh -g ~/.config ~/Documents)"
tarsize=$(stat -c "%s" "$tarfile")
if (( tarsize < $sizelimit )); then
	echo "$tarfile: $tarsize < $sizelimit OK"
else
	echo "$tarfile: $tarsize > $sizelimit TOO BIG, moving to ~/tmp for checking"
	exit
fi

bdirs=".local/bin Code/Mine Documents Pictures/Mine Pictures/Wallpaper-Found Roms Ebooks"
for bd in $bdirs; do
    if [[ -d "$bd" ]]; then
        destd="$bd"
        # convert .some.file to dot.some.file
        [[ "$destd" == "."* ]] && destd="dot$destd"
        #flatten path: some/path/to/dir to Synced/some_path_to_dir
		destd="Synced/${destd//\//_}"
    else
        echo "Error, $bd not a directory."
        continue
    fi
    numf=$(find "$bd" -type f -printf "x"| wc -m)
    echo "-------------"
    echo "Source: $bd"
    echo "Destination: googledrive:$destd"
    echo "Number of files to sync: $numf"
    rclone sync "$bd" googledrive:"$destd"/ \
        --one-file-system \
        --exclude-from "$HOME/.rsync_exclude" \
        --exclude-if-present ".ignore" \
        --delete-excluded \
        --checksum \
        --progress 
    echo
	sleep 5
done
