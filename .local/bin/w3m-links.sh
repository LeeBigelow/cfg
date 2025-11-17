#!/bin/sh
url="$1"
w3m -dump -o display_link_number=1 "$url" \
    | sed '1,/References:/d; /^$/d; s/^\[[0-9]\+\] //'
