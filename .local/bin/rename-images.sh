#!/bin/sh
for img in "$@"; do
	chafa "$img"
	imgpid="$!"
	imv "$img"
	[ -n "$REPLY" ] && exit 
done
