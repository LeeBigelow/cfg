#!/bin/bash
set -e
scriptname="${0##*/}"

usage() {
    cat <<EOF
Usage: $scriptname COMMAND
    Where COMMAND is one of:
    mount [-i IDLEMINS] LUKS_FILE [MOUNT_DIR]
        -i If set will unmount and lock if no open
            files in MOUNT_DIR for IDLEMINS
        A MOUNT_DIR will be created based on LUKS_FILE
            if one isn't given.
    umount MOUNT_DIR
        Unmount and lock MOUNT_DIR
    watch DIRECTORY IDLEMINS
        DIRECTORY will be unmounted and locked if
        idle for IDLEMINS
    create [-s SIZE] [LUKS_FILE|LUKS_DEVICE]
        Note: ~16M will be lost to the luks header, so min size 
        of 20M recommended
        Default size is 4G (max filesize for fat32 thumbdrives)
    grow [-s SIZE] LUKS_FILE
        Grow LUKS_FILE by adding SIZE
        Default growth SIZE of 10M
        Note: Backup before growing luks filesystem
EOF
    exit
}

watch_idle() {
	local watchdir idlemins lastbusy
	watchdir="$1"
	idlemins="$2"
	lastbusy="$EPOCHSECONDS"
	while sleep 1m ; do
		[[ ! -d "$watchdir" ]] && exit
		if ! lsof "$watchdir" >/dev/null ; then
			cur_idlemins=$(( (EPOCHSECONDS - lastbusy) / 60 ))
			(( cur_idlemins >= idlemins )) && luks_umount "$watchdir"
		else
			lastbusy="$EPOCHSECONDS"
		fi
	done
}

luks_mount() {
	local luksfile luksdir luksname opts idlemins
	if [[ "$1" == "-i" ]]; then 
		idlemins="$2"
		shift 2
	fi
	luksfile="$(realpath "$1")"
	if [[ -n "$2" ]]; then
		luksdir="$(realpath "$2")"
	else
		luksdir="${luksfile%.luks}_luks"
	fi
	mkdir -p "$luksdir"
	luksname="$(basename "$luksdir")"
	if sudo cryptsetup open --type luks "$luksfile" "$luksname"; then
		if [[ "$(lsblk -n -o FSTYPE /dev/mapper/"$luksname")" == "vfat" ]]; then 
			opts="-o uid=1000,gid=1000,noatime,nodiratime"
		else
			opts="-o noatime,nodiratime"
		fi
		sudo mount $opts /dev/mapper/"$luksname" "$luksdir"
	fi
	if (( idlemins > 0 )) ; then
		exec sudo "$0" watch "$luksdir" "$idlemins"
	fi
}

luks_umount() {
	local luksdir mntsrc
	luksdir="$(realpath "$1")"
	if ! mntsrc="$(findmnt -n -o 'source' "$luksdir")"; then
		rmdir "$luksdir" && exit || exit 1
	fi
	sudo umount "$luksdir" && rmdir "$luksdir"
	if [[ "$(dirname "$mntsrc")" == "/dev/mapper" ]]; then
		sudo cryptsetup close "$mntsrc" 
	fi
	exit
}

luks_create() {
	local size luksfile luksdir luksname
	size="4294967295" # max filesize for fat32 in bytes (4G)
	if [[ "$1" == "-s" ]]; then
		size="$2"
		shift 2
	fi
	luksfile="$(realpath "$1")"
	if [[ "$luksfile" != "/dev/"* ]]; then
		[[ "$luksfile" != *".luks" ]] && luksfile+=".luks"
		fallocate -l "$size" "$luksfile"
	fi
	luksdir="$(mktemp -d luks.XXXXXXXXXX)"
	luksname="$(basename "$luksdir")"
	sudo cryptsetup luksFormat "$luksfile"
	echo "LUKS container created, need to unlock to create filesytem..."
	sudo cryptsetup luksOpen "$luksfile" "$luksname"
	sudo mkfs.ext4 -L "$luksname" -m 0 /dev/mapper/"$luksname"
	sudo mount /dev/mapper/"$luksname" "$luksdir"
	sudo chmod a+w "$luksdir"
	sudo umount "$luksdir"
	rmdir "$luksdir"
	sudo cryptsetup -v close "$luksname"
}

luks_grow() {
	local size luksfile luksname 
	size="10M"
	if [[ "$1" == "-s" ]]; then
		size="$2"
		shift 2
	fi
	luksfile="$(realpath "$1")"
	luksname="$(mktemp -u luks.XXXXXXXXXX)"
	truncate -s "+$size" "$luksfile"
	sudo cryptsetup luksOpen "$luksfile" "$luksname"
	sudo cryptsetup resize "$luksname"
	sudo e2fsck -f /dev/mapper/"$luksname"
	sudo resize2fs /dev/mapper/"$luksname"
	sync
	sudo cryptsetup close "$luksname"
}

case "$1" in
	mount) shift; luks_mount "$@" ;;
	umount) shift; luks_umount "$@" ;;
	watch) shift; watch_idle "$@" ;;
	create) shift; luks_create "$@" ;;
	grow) shift; luks_grow "$@" ;;
	*) usage ;;
esac
