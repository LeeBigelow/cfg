#!/bin/bash

# custom icon names
# incase icon isn't named app_id
declare -A CUST_ICONS=(
	# [app_id]="some_icon_name or path"
	# [foot]="utilities-terminal"
)

set_icon() {
	# using app_id as icon name unless told otherwise
	local app_id="$1"
	local app_title="$2"
	local icon="$app_id"
	# set custom icons if provided
	if [[ -v CUST_ICONS[$app_id] ]]; then
		icon="${CUST_ICONS[$app_id]}"
	fi	
	# override some icons based on title
	case "$app_title" in
		*"- VIM") icon="gvim" ;;
		*"- VIFM") icon="vifm";;
		"Netflix"*) icon="netflix";;
	esac
	echo "$icon"
}


row=$(swaymsg -t get_tree \
	| jq  -r ' ..
		| objects
		| select(.type == "workspace") as $ws
		| ..
		| objects
		| select(has("app_id") or has(".window_properties.class"))
		| (if .focused == true then "*" else "-" end) as $focused
		| [$ws.name, .id, $focused, .app_id // .window_properties.class, .name]
		| join(" ")' \
	| while read ws_name win_id foc app_id title; do
		icon="$(set_icon "${app_id%.float}" "$title")"
		[[ "$foc" == "-" ]] && foc=" "
		[[ "$ws_name" == "__i3_scratch" ]] && ws_name="S"
		printf "%s[%s] %s: %s \t\t\t\t\t\t\t\t\t #id:%s\u0000icon\u001f%s\n" \
			"$foc" "$ws_name" "$app_id" "$title" "$win_id" "$icon"
	done \
	| fuzzel -f 'Monospace:size=12' -w 60 --select='*[' --dmenu)

if [ ! -z "$row" ]
then
	winid="${row##*#id:}"
    swaymsg "[con_id=$winid] focus"
fi
