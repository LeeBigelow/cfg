#!/bin/sh
outfile="out"
usage() {
    cat<<EOF
Usage: ${0##*/} [-o OUTFILE] FILE1 FILE2 ....
    OUTFILE should have no extension (will use .mkv).
    Will attempt to convert and join video files together into OUTFILE.
    If not given will use out.mkv
EOF
    exit 1
}
[ $# -eq 0 ] && usage

while getopts "o:" opt; do
    case $opt in
        o) outfile="$OPTARG" ;;
        *) usage ;;
    esac
done
shift $(( $OPTIND - 1 ))

#filelist=$(mktemp -p "$PWD" ffcat.XXXX)
#printf "file '%s'\n" "$@" | sort -V > $filelist
for fname in "$@"; do
    echo "--- $fname ---"
    tsname="${fname%.*}.ts"
    ffmpeg -hide_banner -v 8 -i "$fname" -c copy -bsf:v h264_mp4toannexb -f mpegts - >> "$outfile".ts
done

ffmpeg -hide_banner -v 8 -i "$outfile.ts" -c copy "$outfile".mkv
rm "$outfile".ts
