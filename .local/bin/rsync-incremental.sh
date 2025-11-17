#!/bin/bash

# A script to perform incremental backups using rsync

set -o errexit
set -o nounset
set -o pipefail

SOURCE_DIR="$1"
if [[ ! -d "$1" ]]; then
	echo "Usage: ${0##*/} SOURCE_DIR BACKUP_DIR"
	exit
fi
BACKUP_DIR="$2"
LABEL="$(realpath "$SOURCE_DIR")"
LABEL="${LABEL#/}"
LABEL="${LABEL//\//_}"
DATETIME="$(date '+%Y-%m-%d_%H:%M:%S')"
BACKUP_PATH="${BACKUP_DIR}/${LABEL}_${DATETIME}"
LATEST_LINK="${BACKUP_DIR}/${LABEL}_latest"


mkdir -p "${BACKUP_DIR}"

rsync \
	--verbose \
	--archive \
	--one-file-system \
   	--delete \
	--delete-excluded \
	--cvs-exclude \
	--exclude-from="$HOME/.rsync_exclude" \
	--link-dest "${LATEST_LINK}" \
	"${SOURCE_DIR}/" "${BACKUP_PATH}"

rm -rf "${LATEST_LINK}"
ln -s "${BACKUP_PATH}" "${LATEST_LINK}"

