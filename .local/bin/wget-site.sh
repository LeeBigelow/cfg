#!/bin/sh
# may want to add --no-host-directories \
# --domains "$domain" \
# domain="${1#*://}"
# domain="${domain%%/*}"
wget \
    -e robots=off \
    --no-parent \
    --recursive \
    --no-clobber \
    --page-requisites \
    --convert-links \
    --adjust-extension \
    --no-parent \
    --wait=2 \
    --random-wait \
    "$1"
