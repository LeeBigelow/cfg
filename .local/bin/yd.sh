#!/bin/bash
shopt -s extglob

scriptname=${0##*/}
highlight=$(tput bold; tput setaf 5)
normal=$(tput sgr0)
complete_sound="/usr/share/sounds/freedesktop/stereo/complete.oga"
error_sound="/usr/share/sounds/freedesktop/stereo/dialog-error.oga"
now=false
skip=false
verbose=false
concur=3
retry=10
rlimit="1M"
downdir="$PWD"
ytdopts=""
ytdcmd="yt-dlp --downloader native --progress --no-check-certificates"
resumefile=""
outfile=""
waitpid=""
piddir="$HOME/.config/${scriptname%.sh}"

mkdir -p "$piddir"

usage() {
	cat <<EOF
Usage: $scriptname [-h] [-n] [-s] [-v] [-b BROWSER_COOKIE_DIR ]
            [-c CONCURRENT_FRAGMENTS] [-d DIRECTORY_NAME]
            [-l LIMIT_RATE] [-o OUT_FILENAME] [-r NUMBER_RETRIES]
            [OUT_FILENAME | RESUME_FILE | URL | CURL_STRING]
    -h  Help. Print this help
    -n  No waiting, get Now
    -s  Skip unavailable fragments. (default: fail if unavailable) 
    -v  Verbose output
    -b  Browser profile directory for cookies (BROWSER:PROFILE_DIR)
    -c  Concurrent number of fragments set to CONCURRENT_FRAGMENTS (default: 3)
    -d  Download directory set to DIRECTORY_NAME (default: current directory)
    -l  Limit per fragment rate to LIMIT_RATE (default: 1M)
    -o  Output set to OUT_FILENAME. It will have ".mkv" appended. Can be used with
        positional arguemnt URL or CURL_STRING
    -r  Retry NUMBER_RETRIES times if failure (default: 10)

    Only one positional argument may be given.
    OUT_FILENAME is the same as "-o". If both are given "-o" will be used.
    RESUME_FILE must end in ".resume" and contain  a url or curl string. The
        OUT_FILENAME will be set to RESUME_FILE with ".resume" changed to
        ".mkv"  (any other OUT_FILENAME given will be ignored).
    URL must begin with "http://" or "https://".
    CURL_STRING must follow the format Firefox's "Copy as cURL" option sends.
        In Firefox: Network Monitor(Ctrl-Shift-E), Reload page if needed,
        Right-Click item, Copy Value->Copy as cURL

    Will using curl info, or url, found in clipboard unless a URL is passed directly.
    If no OUT_FILENAME is given one will be asked for.
EOF
}

while getopts "hnsvb:c:d:l:r:o:" opt; do
	case "$opt" in
		h) usage; exit ;;
		n) now=true; echo "NOW: on" ;;
		s) skip=true; echo "SKIP: on" ;;
		v) verbose=true; echo "VERBOSE: on" ;;
		b) profiledir="$OPTARG"; echo "PROFILEDIR: $profiledir" ;;
		c) concur="$OPTARG"; echo "CONCURRENT FRAGMENTS: $concur" ;;
		d) downdir="$PWD"; echo "DOWNLOAD DIRECTORY: $downdir" ;;
		l) rlimit="$OPTARG"; echo "FRAGMENT RATE LIMIT: $rlimit" ;;
		r) retry="$OPTARG"; echo "RETRIES: $retry" ;;
		o) outfile="$OPTARG"; echo "OUTPUT FILE: $outfile"  ;;
		*) usage; exit 1 ;;
	esac
done
shift $(( OPTIND - 1 ))

termtitle () {
	printf "\e]2;%s\a" "$1"
}

is_url() {
	case "$1" in
		http*) url="$1"; return 0 ;;
		*) return 1 ;;
	esac
}


parse_curlstr() {
	# expects global resumestr set to multiline curl string
	url="${resumestr#curl \'}"
	url="${url%%\'*})"
	$verbose && echo "CURL URL: $url"
	ytdopts=""
	# IFS to newline for line by line string parsing
	local IFS='
'
	for line in $resumestr; do
		# strip leading spaces and trailing backslash, maybe firefox specific
		line="${line##+([[:space:]])}"
		line="${line% \\}"
		case "$line" in
			*Encoding*) continue ;; # yt-dlp doesnt like encoding header
			-H*) ytdopts="$ytdopts --add-header ${line#-H }" ;;
		esac
	done
	$verbose && echo "YTDOPTS: $ytdopts"
	if [[ -z "$url" || -z "$ytdopts" ]]; then
		echo "!!! Error parsing curl string: $resumestr"
		exit 1
	fi
}

termtitle "$scriptname"

case "$1" in
	*".resume")
		resumefile="$1"
		$verbose && echo "RESUME FILE: $resumefile"
		outfile="${resumefile%.resume}"
		resumestr=$(< "$resumefile")
		is_url "$resumestr" || parse_curlstr ;;
	"http"*)
		url="$1"; resumestr="$1" ;;
	"curl '"*)
		resumestr="$1"; parse_curlstr ;;
	*)
		[[ -z "$outfile" ]] && outfile="$1" ;;
esac

while [[ -z "$url" ]]; do
	resumestr="$(wl-paste)"
	if [[ -z "$resumestr" ]]; then
		echo "Copy a URL or CURL STRING to clipboard and press ENTER" 
		read -r -n 1
		continue
	fi
	wl-copy -c
	is_url "$resumestr" || parse_curlstr
done

if ! cd "$downdir"; then
	echo "!!! Error, couldn't enter dir: $downdir"
	exit 1
fi

if [[ -z "$outfile" ]]; then
	read -e -p "Enter Filename (no ext)> " outfile
	[[ -z "$outfile" ]] && exit 1
fi

resumefile="${outfile}.resume"
[[ ! -s "$resumefile" ]] && echo -n "$resumestr" > "$resumefile"

termtitle "$scriptname: $outfile"
! $verbose && clear	
echo "DOWNLOAD DIRECTORY: $downdir"
echo "FILENAME: $highlight${outfile}.mkv$normal"
echo "PID: $$"

# assemble the command
ytdcmd="$ytdcmd -r $rlimit -N $concur -R $retry --fragment-retries $retry"

[[ -n "$profiledir" ]] && ytdcmd="$ytdcmd --cookies-from-browser $profiledir"

$skip && ytdcmd="$ytdcmd --skip-unavailable-fragments" \
	|| ytdcmd="$ytdcmd --abort-on-unavailable-fragment"

$verbose || ytdcmd="$ytdcmd --no-warnings --quiet"

ytdcmd="$ytdcmd -o '$outfile.mkv' $ytdopts '$url'"

#create lockpid file for this process
echo "$outfile" > "$piddir"/"$$"

if ! $now; then
	termtitle "P $scriptname: $outfile"
	waiting_since=$(date +'%I:%M%P')
fi

while ! $now; do
	waitpids=$(ls -rt "$piddir")
	[[ -z "$waitpids" ]] && { printf '\n'; break; }
	for waitpid in $waitpids; do
		case "$(ps -o "comm=" "$waitpid")" in
			*"$scriptname") break ;; 
			*) rm "$piddir/$waitpid" ;;
		esac
	done
	[[ "$waitpid" = "$$" ]] && { printf '\n'; break; }
	read -r waitfname < "$piddir/$waitpid"
	printf "\r%s Currently waiting on: %s %s %s" \
		"$waiting_since" \
		"$waitpid" \
		"$waitfname" \
		"$(tput el)"
	sleep 1m
done

termtitle "D $scriptname: $outfile"
echo "DOWNLOADING ($$): $highlight${outfile}.mkv$normal"

echo "$ytdcmd"

if eval "$ytdcmd"; then
	termtitle "C $scriptname: $outfile"
	msg="Completed $outfile, removing resume file"
	echo "$msg"
	# notify-send -i "emblem-default" -u low "$scriptname" "$msg"
	# mpv --volume=40 --terminal=no "$complete_sound"
	rm "$resumefile"
else
	termtitle "E $scriptname: $outfile"
	msg="!!! There was an error getting $outfile, keeping resume file"
	echo "$msg"
	# notify-send -i "dialog-error" -u low "$scriptname" "$msg"
	# mpv --volume=60 --terminal=no "$error_sound"
fi
