# Hint starting Sway
[[ -s $HOME/.profile ]] && source $HOME/.profile 


# if [[ -z "$WAYLAND_DISPLAY" && -z "$DISPLAY" \
# 		&& -n "$XDG_VTNR" && "$XDG_VTNR" -eq 1 ]]; then
# 	export XDG_CURRENT_DESKTOP="sway:wlroots"
# 	exec sway >/dev/null 2>&1
# fi

# if [[ -z $DISPLAY ]] && [[ "$(tty)" == "/dev/tty1" ]]; then
#         echo
#         echo 'To start Sway, simply type sway in the Linux console.'
#         echo
# fi

