#!/bin/bash

#fdisk /dev/sda <<EOF
#n
#p
#1
#
#+100M
#n
#p
#2
#+5G
#t
#2
#82
#n
#3
#
#
#a
#1
#p
#w
#EOF

sleep 60

#setup encrypted partition
cryptsetup luksFormat -l 512 -c blowfish -h sha512 /dev/sda3 
sleep 10
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

mkdir -p /mnt/gentoo/boot
mount /dev/sda1 /mnt/gentoo/boot
cd /mnt/gentoo

#Download the latest stage3 and extract it.
wget http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-hardened/stage3-amd64-hardened-20140508.tar.bz2
tar -xf /mnt/gentoo/stage3-amd64-hardened-*.tar.bz2 -C /mnt/gentoo

#get the latest portage tree
emerge --sync

#copy the zfs cache from the live system to the chroot
mkdir -p /mnt/gentoo/etc/zfs
cp /tmp/zpool.cache /mnt/gentoo/etc/zfs/zpool.cache


vim /mnt/gentoo/etc/portage/make.conf

mirrorselect -i -r -o >> /mnt/gentoo/portage/make.conf

cp -L /etc/resolv.conf /mnt/gentoo/etc/

mount -t proc proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev

chroot /mnt/gentoo /bin/bash
