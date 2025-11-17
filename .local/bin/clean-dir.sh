#!/bin/sh
set -e
days=7
usage () {
    cat << EOF
USAGE: ${0##*/} [-y] DIR1 DIR2 ...
    Will delete $days day old files from DIR1 DIR2 ....
    -y  Don't ask, just delete. Otherwise will list found files
        and ask permission to delete.
EOF
    exit
}

[ "$#" -lt 1 ] && usage

ask=true
if [ "$1" = "-y" ]; then
    ask=false
    shift 1
fi

echo "Checking for files $days days old in $@"
for d in "$@"; do
    if [ ! -d "$d" ]; then
        echo "Not a directory: $d"
        usage
    fi
    if $ask; then
        count=$(find "$d" -type f -mtime +$days | tee /dev/stderr | wc -l)
        if [ $count -eq 0 ]; then
            echo "No files older than $days days in $d, skipping ..."
            continue
        fi
        ans="no"
        read -p "$count files are older than $days days, delete (yes/no)? " ans
        if [ "$ans" != "yes" ]; then
            echo "Skipping ..."
            continue
        fi
    fi
    count=$(find "$d" -type f -mtime +$days -printf "%p\n" -delete | wc -l)
    echo "$count files deleted from $d"
done

