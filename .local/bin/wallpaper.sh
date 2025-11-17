#!/bin/bash
# needs: curl, zenity, magick, swaybg, trans from translate-shell
wallpaperdir="$HOME/Pictures/Wallpaper"
wikimediadir="$wallpaperdir/Wikimedia"
wallpaper_dotfile="$HOME/.wallpaper"

usage() {
	cat <<EOF
Usage: ${0##*/} [-v] [ -c | -d | -e | -w  ...
        | -g WIKIMEDIA_URL | -l IMAGE_PATH | -s IMAGE_PATH | -r IMAGE_PATH ]
    -v Verbose
    -c Change wallpaper. 1/2 of the time from wikipedia, 1/2 from existing
    -d Delete current and change. Sets as zero sized file to stop future downloading.
    -e Existing image set as wallpaper 
    -w Wikimedia image set as wallpaper
    -g Get image from wikimedia page WIKIMEDIA_URL, process and set as wallpaper.
    -l Label IMAGE_PATH using it's filename. ' - ' becomes a newline.
    -s Set IMAGE_PATH as wallpaper
    -r Rename, translate and relabel IMAGE_PATH. IMAGE_PATH needs to be
        a wikimedia image. It will be redownloaded for relabeling.
    Will process the first option found and ignore the rest.
    Wallpaper directory: $wallpaperdir
    Wikimedia Wallpaper directory: $wikimediadir
EOF
	exit 1
}

path_to_title() {
	local title="$1"
	title="${title##*/}"
	title="${title%.*}"
	title="$(echo -e "${title//\%/\\x}")"
	title="${title//\'/’}"
	title="${title//\"/”}"
	title="${title//_/ }"
	title="${title//–/-}" #n-dash
	title="${title//—/-}" #m-dash
	title="${title% - Google*}"
	echo "$title"
}

set_wallpaper() {
	local imagepath="$1"
	if [[ ! -s "$imagepath" ]]; then 
		echo "!!! ERROR, empty image?: $imagepath" >&2
		exit 1
	fi

	$verbose && echo "LINKING $imagepath to $wallpaper_dotfile" >&2
	ln -sf "$imagepath" "$wallpaper_dotfile"

	case $XDG_CURRENT_DESKTOP in
		*gnome*|*GNOME*|*ubuntu*)
			$verbose && echo "Setting $XDG_CURRENT_DESKTOP wallpaper with gsettings" >&2
			gsettings set org.gnome.desktop.background picture-uri "$wallpaper_dotfile"
			gsettings set org.gnome.desktop.background picture-uri-dark "$wallpaper_dotfile"
			;;
		*niri*|*sway*|*labwc*|*wlroots*)
			$verbose && echo "Setting $XDG_CURRENT_DESKTOP wallpaper with swaybg" >&2
			pkill swaybg
			swaybg -o '*' -m fit -c '#000000' -i "$HOME/.wallpaper" >/dev/null 2>&1 &
			;;
		Hyprland)
			$verbose && echo "Setting $XDG_CURRENT_DESKTOP wallpaper with hyprpaper" >&2
			hyprctl hyprpaper preload "$HOME/.wallpaper"
			hyprctl hyprpaper wallpaper ",contain:$HOME/.wallpaper"
			;;
		*)
			echo "ERROR, XDG_CURRENT_DESKTOP: $XDG_CURRENT_DESKTOP" >&2
			if [[ -n "$XDG_CURRENT_DESKTOP" ]]; then
				echo "Unrecognized, nothing set" >&2
			else
				echo "XDG_CURRENT_DESKTOP unset, unsure how to set background." >&2
			fi
			exit 1
			;;
	esac
	exit 0
}

existing_set() {
	local imagepath=""
	if imagepath="$(find -L "$wallpaperdir" -type f -size +1 | shuf -n1)"; then
		$verbose && echo "EXISTING FILE: $imagepath" >&2
		set_wallpaper "$imagepath"
	fi
	echo "!!! ERROR, couldn't find existing in: $wallpaperdir" >&2
	exit 1
}

label() {
	local width=1920
	local height=1080
	local font="$(fc-match -f '%{file}' 'serif')"
	local pts=20
	local label=""
	local labeledpath=""
	local imagepath="$1"
	if [[ ! -s "$imagepath" ]]; then
		echo "!!! ERROR labelling, empty file?: $imagepath" >&2
		exit 1
	fi

	labeledpath="${imagepath%/*}/labeled-${imagepath##*/}"
	label="$(path_to_title "$imagepath")"
	label="${label// - /\\n}"

	if ! magick "$imagepath" -resize "$width"x"$height" -background Black \
			-gravity center -extent "$width"x"$height" \
			-font "$font" -pointsize "$pts" \
			-draw "gravity SouthEast fill black text 10,4 ${label@Q}" \
			-draw "gravity SouthEast fill white text 8,6 ${label@Q}" \
			"$labeledpath"; then
		echo "!!! ERROR labeling: $imagepath" >&2
		return 1
	fi

	$verbose && echo "CREATED: $labeledpath" >&2
	echo "$labeledpath"
	return 0
}

wikimedia_fetch() {
	# arg should be destination path with wikimedia filename
	local fpath="$1"
	local url="http://commons.wikimedia.org/w/index.php?title=Special:Redirect/file/${fpath##*/}&width=1920&height=1080"
	$verbose && echo "WIKIMEDIA FETCH: $url" >&2

	if [[ -s "$imagepath" ]]; then
		$verbose && echo "ALREADY EXISTS: $fpath" >&2
		return 2
	elif [[ -e "$imagepath" ]]; then
		$verbose && echo "EMPTY FILE so ignoring: $fpath" >&2
		return 1
	fi

	if ! curl -o "$fpath" -s -L "$url"; then
		echo "!!! ERROR, curl couldn't fetch: $url" >&2
		return 1
	elif file -b --mime-type "$fpath" | grep -v "image"; then
		echo "!!! ERROR, fetched but not an image: $fpath" >&2
		rm "$fpath"
		return 1
	fi
	
	$verbose && echo "FETCHED: $fpath"
	return 0
}

relabel() {
	local oldpath="$1"
	local newpath
	local labeledpath
	local title=""

	title="$(path_to_title "$oldpath")"
	read -r -n 1 -p "Attempt Translation (y/N)? " ans
	[[ "$ans" == "y" ]] \
	   	&& newpath="$(trans -b "$title")" \
		|| newpath="$title"

	read -e -p "Enter New Title: " -i "$newpath" newpath
	[[ -z "$newpath" ]] && exit 1
	newpath=${newpath// /_}
	newpath="${oldpath%/*}/${newpath}.${oldpath##*.}"

	mv -v "$oldpath" "$oldpath.oldlabel"
	if wikimedia_fetch "$oldpath"; then
		rm -v -i "$oldpath.oldlabel"
		mv -v "$oldpath" "$newpath"
	else
		mv -v -f "$oldpath.oldlabel" "$oldpath"
		echo "!!! ERROR, couldn't fetch for relabeling $oldpath" >&2
		exit 1
	fi

	if labeledpath="$(label "$newpath")"; then
		echo "Labeledpath: $labeledpath" >&2
		mv -v -f "$labeledpath" "$newpath"
		ln -v -s "$newpath" "$oldpath"
		xdg-open "$newpath"
	fi
}

wikimedia_set() {
	local try tries=5
	local imagepath=""
	local labeledpath=""
	local wikimedia_image_page="$1"
	local wikimedia_url="https://commons.wikimedia.org/wiki/Special:RandomInCategory/Google_Art_Project_paintings"
	# local wikimedia_url="https://commons.wikimedia.org/wiki/Special:RandomInCategory/Files_from_Google_Arts_%26_Culture"

	if ! mkdir -p "$wikimediadir"; then
		echo "!!! ERROR making: $wikimediadir" >&2
		exit 1
	fi

	for (( try=0; try<tries; try++ )); do
		if [[ -n "$wikimedia_image_page" ]]; then
			# given a page, so downlod here 
			wikimediadir="$PWD"
			break
		fi
		# only want redirect url so
		# just get the headers not content, follow location redirects, 
		# no progress info, dump headers to null, and print out last url
		if ! wikimedia_image_page="$(curl -ILs -o /dev/null \
				-w '%{url_effective}' "$wikimedia_url")"; then
			echo "!!! ERROR fetching with curl, no internet?" >&2
			sleep 2
			continue
		fi

		case "${wikimedia_image_page@L}" in
			*detail*)
				$verbose && echo "!!! DETAIL IMAGE trying again: $wikimedia_image_page" >&2
				sleep 2
				wikimedia_image_page=""
				continue ;;
			*jpg|*jpeg|*png)
				break ;;
			*)
				$verbose && echo "!!! NOT AN IMAGE? Try again: $wikimedia_image_page" >&2
				sleep 2
				wikimedia_image_page=""
				continue ;;
		esac
	done
	if (( try >= 5 )); then
		$verbose && echo "Failed to get a url in $try tries" >&2
		return 1
	elif [[ -z "$wikimedia_image_page" ]]; then
		$verbose && echo "Failed to get a url"
		return 1
	fi

	imagepath="$wikimediadir/${wikimedia_image_page##*File:}"
	wikimedia_fetch "$imagepath" || case "$?" in
		2) set_wallpaper "$imagepath" ;; # not fetched, already exists
		*) $verbose && echo "Could not fetch from wikimedia." >&2
			return 1 ;;
	esac

	if labeledpath="$(label "$imagepath")"; then 
		$verbose && echo "Moving $labeledpath -> $imagepath" >&2
		if mv -f "$labeledpath" "$imagepath"; then
			set_wallpaper "$imagepath"
		else
			echo "!!! ERROR, could move $labeledpath to $imagepath"
			exit 1
		fi
	else 
		existing_set
	fi
}

wallpaper_change() {
	# Third of the time use wikimedia
	if (( RANDOM % 2 )); then
		$verbose && echo "Trying to use existing..."
		existing_set
	fi
	$verbose && echo "Trying to use wikimedia..."
	wikimedia_set || existing_set
}

wallpaper_delete() {
	local imagepath=""
	imagepath="$(realpath "$wallpaper_dotfile")"
	ans="n"
	question="Current wallpaper:\n$imagepath\n\nDelete (zero out) current wallpaper and set a new one (y/N)? " 
	if ! zenity --icon="edit-delete" \
		--default-cancel \
		--title="Delete Current Wallpaper" \
		--width=500 \
		--question \
		--text "$question" >/dev/null 2>&1
	then
		exit 1
	fi
	echo -n > "$imagepath"
	wallpaper_change

}

[[ $# -eq 0 ]] && usage

verbose=false

while getopts "vcdewg:l:r:s:" opt; do
	case "$opt" in
		v) verbose=true ;;
		c) wallpaper_change ;;
		d) wallpaper_delete ;;
		w) wikimedia_set || existing_set ;;
		e) existing_set ;;
		g) wikimedia_set "$OPTARG" ;;
		l) label "$(realpath "$OPTARG")" ;;
		r) relabel "$(realpath "$OPTARG")" ;;
		s) set_wallpaper "$(realpath "$OPTARG")" ;;
		*) usage ;;
	esac
done
shift $(( OPTIND - 1 ))

[[ $# -ne 0 ]] && usage
