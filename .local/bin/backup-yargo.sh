#!/bin/bash
SOURCE_DIR="/home/yargo"
BACKUP_DIR="/mnt/Data/backup.gcfs"

echo "gocryptfs/rsync: Backing up $SOURCE_DIR in $BACKUP_DIR..."
if [[ ! -d "$BACKUP_DIR" ]]; then
	gocryptfs --init "$BACKUP_DIR"
fi

DEC_DIR="${BACKUP_DIR%.gcfs}_gcfs"
[[ -d "$DEC_DIR" ]] && gcfs-umount.sh "$DEC_DIR"

if gcfs-mount.sh "$BACKUP_DIR"; then
	rsync-incremental.sh "$SOURCE_DIR" "$DEC_DIR"
	gcfs-umount.sh "$DEC_DIR"
fi
