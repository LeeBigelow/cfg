#!/bin/sh
set -e
usage() {
    cat <<EOF
Usage:  ${0##*/} -v VIDEO_FILE -a AUDIO_FILE [MERGED_FILE]
	If MERGED_FILE not given will use VIDEO_FILE-merged.mkv
	Uses first video stream of VIDEO_FILE and first audio stream of AUDIO_FILE
	Will append ".mkv" to MERGED_FILE name if needed.
EOF
	exit 1
}

[ $# -eq 0 ] && usage && exit 1

while getopts "hv:a:" opt ; do
    case "$opt" in
        v) video_file="$OPTARG" ;;
        a) audio_file="$OPTARG" ;;
        *) usage ;;
    esac
done
shift $(( OPTIND - 1 ))

[ $# -gt 1 ] && usage

if [ ! -e "$video_file" ]; then
	echo "Video file not found: $video_file"
	exit
elif [ ! -e "$audio_file" ]; then
	echo "Audio file not found: $audio_file"
	exit
fi

merged_file="$1"
if [ -z "$merged_file" ]; then 
	merged_file="$video_file-merged.mkv"
elif [ "${merged_file##*.}" != "mkv" ]; then
	merged_file+=".mkv"
fi

ffmpeg -hide_banner	-v 8 \
	-i "$video_file" -i "$audio_file" \
	-map 0:v:0 \
	-map 1:a:0 \
	-c copy \
	"$merged_file"

[ $? -ne 0 ] && exit

rm -i "$video_file" "$audio_file"	

