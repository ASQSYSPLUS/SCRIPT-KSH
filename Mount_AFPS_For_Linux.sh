#!/bin/bash

#VERSION BASIQUE----------------------------------------------------------------------
#Mount MacOs by using paragon APFS for linux

lsmod | grep uapfs
sudo mount -t uapfs -o subvolumes /dev/sda2 ../apfs-fuse/
mount | grep uapfs
