#!/bin/sh
grep -r . /sys/module/zswap/parameters/
sudo grep -r . /sys/kernel/debug/zswap
