#!/bin/bash
gpgenc=false
if [[ "$1" == "-g" ]]; then
	gpgenc=true
	shift
fi
srcd="$1"
destd="$2"

usage() {
	echo "Usage: $0 [-g] SOURCE_DIR DEST_DIR"
	echo "    Creates SOURCE_DIR.tar.zst in DEST_DIR"
	echo "    -g creates SOURCE_DIR.tar.gpg in DEST_DIR"
	echo "    Excludes dirs containing a .ignore file"
	echo "    Excludes items in $HOME/.rsync_exclude"
	echo "    Renames .dir.tar.zst to dot.dir.tar.zst"
	exit
}

for d in "$srcd" "$destd"; do
	[[ ! -d "$d" ]] && echo "Not a directory: $d" && usage
done

destd="$(realpath "$destd")"

cd "$(dirname "$srcd")"
srcd="$(basename "$srcd")"

# convert .dirs.tar.zst to dot.dirs.tar.zst
[[ "$srcd" == "."* ]] \
	&& outf="$destd/dot$srcd.tar" \
	|| outf="$destd/$srcd.tar"

$gpgenc \
	&& outf+=".gpg" \
	|| outf+=".zst"

taropts="--create --exclude-tag=.ingore --exclude-from=$HOME/.rsync_exclude"

if $gpgenc; then
	tar $taropts "$srcd" | gpg -e -o "$outf" && echo "$outf"
else
	tar $taropts --zstd --file "$outf" "$srcd" && echo "$outf"
fi

