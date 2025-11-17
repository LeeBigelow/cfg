#!/bin/sh
idletime="10m"

usage() {
	cat<<EOF
Usage: ${0##*/} [-i IDLE_TIME] [-u] GOCRYPTFS_DIR
	Defaults to mounting GOCRYPTFS_DIR
	-i Unmount if idle for IDLE_TIME
	-u Unmount GOCRYPTFS_DIR
EOF
exit 1
}

gcfs_umount() {
	dec_dir="$1"
	fusermount -u "$dec_dir" && rmdir "$dec_dir"
	exit
}

gcfs_mount() {
	enc_dir="${1%/}"
	if [ ! -d "$enc_dir" ]; then
		echo "Not a direcory: $encdir"
		usage
	fi

	dec_dir="${enc_dir%.gcfs}_gcfs"

	if mkdir -p "$dec_dir"; then 
		printf "$enc_dir "
		if ! gocryptfs -ko noatime -i "$idletime" "$enc_dir" "$dec_dir"; then
			rmdir "$dec_dir"
			usage
		fi
	fi
}

[ $# -eq 0 ] && usage

case "$1" in
	-h) usage ;;
	-i) idletime="$2"; shift 2 ;;
	-u) shift; gcfs_umount "$@" ;;
	*) gcfs_mount "$@" ;;
esac

