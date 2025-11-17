#!/bin/sh
# need to run as root
[ "$UID" -ne 0 ] && exec sudo "$0" "$@"

# touch screen device
device_id=$(basename /sys/bus/hid/devices/0018:2A94:D64D.*)


driverdir="/sys/bus/hid/drivers/hid-multitouch"
if [ "$1" == "-e" ]; then
	echo "Enabled Device_ID: $device_id"
	echo "$device_id" > "$driverdir/bind"
else
	echo "Disable Device_ID: $device_id"
	echo "$device_id" > "$driverdir/unbind"
fi
