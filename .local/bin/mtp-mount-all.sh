#!/bin/sh
# need gvfs-fuse installed to see mounts in /run/user/XXXX/gvfs/
gio mount -li | awk -F= '{if(index($2,"mtp") == 1)system("gio mount "$2)}'
ls -d /run/user/$(id -u)/gvfs/*
