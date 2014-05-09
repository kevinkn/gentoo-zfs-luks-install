#!/bin/bash

#setup encrypted partition
#aes-xts-plain64 was chosen due to speed, xts-essiv SHOULD be more secure, but about half as slow, on aes-ni I was getting about 200MBps
cryptsetup luksFormat -l 512 -c aes-xts-plain64 -h sha512 /dev/sda3
cryptsetup luksOpen /dev/sda3 cryptroot

#setup ZFS
zpool create -f -o ashift=12 -o cachefile=/tmp/zpool.cache -O normalization=formD -m none -R /mnt/gentoo hactar /dev/mapper/cryptroot
zfs create -o mountpoint=none -o compression=lzjb hactar/ROOT
#rootfs
zfs create -o mountpoint=/ hactar/ROOT/rootfs
#system mountpoints were seperated so that we can set nodev and nosuid as mount options
zfs create -o mountpoint=/opt hactar/ROOT/rootfs/OPT
zfs create -o mountpoint=/usr hactar/ROOT/rootfs/USR
zfs create -o mountpoint=/usr/src -o sync=disabled hactar/ROOT/rootfs/USR/SRC
zfs create -o mountpoint=/var hactar/ROOT/rootfs/VAR
#portage
zfs create -o mountpoint=none hactar/GENTOO
zfs create -o mountpoint=/usr/portage hactar/GENTOO/portage
zfs create -o mountpoint=/usr/portage/distfiles -o compression=off hactar/GENTOO/distfiles
zfs create -o mountpoint=/usr/portage/packages -o compression=off hactar/GENTOO/packages
zfs create -o mountpoint=/var/tmp/portage -o sync=disabled hactar/GENTOO/build-dir
#homedirs
zfs create -o mountpoint=/home hactar/HOME
zfs create -o mountpoint=/root hactar/HOME/root
#replace user with your username
zfs create -o mountpoint=/home/macha hactar/HOME/macha

cd /mnt/gentoo

#Download the latest stage3 and extract it.
wget http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-hardened/stage3-amd64-hardened-20140508.tar.bz2
tar -xf /mnt/gentoo/stage3-amd64-hardened-*.tar.bz2 -C /mnt/gentoo

#get the latest portage tree
emerge --sync

#copy the zfs cache from the live system to the chroot
mkdir -p /mnt/gentoo/etc/zfs
cp /tmp/zpool.cache /mnt/gentoo/etc/zfs/zpool.cache
