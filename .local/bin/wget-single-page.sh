#!/bin/sh
#may want to add  -e robots=off
wget \
    --A.html,.png,.jpg,.webp \
    --adjust-extension \
    --span-hosts \
    --convert-links \
    --backup-converted \
    --page-requisites \
    "$@"
