#!/bin/sh
set -e
outfile="out"
usage() {
    cat<<EOF
Usage: ${0##*/} [-o OUTFILE] FILE1 FILE2 ....
    OUTFILE should have no extension (will use .mkv).
    Will attempt to concat video files together into OUTFILE.
    Files should have same codecs and dimensions. If not use ffmpeg-convert-join.sh
    If OUTFILE not given will use "out.mkv"
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
shift $(( $OPTIND-1 ))

filelist=$(mktemp -t ffmpeg-join-XXXXXX.txt)
printf "file '$PWD/%s'\n" "$@" | sort -V > "$filelist"

ffmpeg -hide_banner -v 8 -f concat -i "$filelist" -c copy "$outfile".mkv

rm $filelist
