#!/bin/sh
gio mount -li | awk -F= '{if(index($2,"mtp") == 1)system("gio mount -u "$2)}'

