#!/bin/bash

echo "=sys-kernel/genkernel-3.4.40 ~amd64       #needed for zfs and encryption support" >> /etc/portage/package.accept_keywords
emerge sys-kernel/genkernel
emerge sys-kernel/hardned-sources                #or gentoo-sources

#patch the kernel

#If you want to build the modules into the kernel directly, you will need to patch the kernel directly.  Otherwise, skip the patch commands.
env EXTRA_ECONF='--enable-linux-builtin' ebuild /usr/portage/sys-kernel/spl/spl-0.6.2.ebuild clean configure
(cd /var/tmp/portage/sys-kernel/spl-0.6.2/work/spl-spl-0.6.2 && ./copy-builtin /usr/src/linux)
env EXTRA_ECONF='--with-spl=/usr/src/linux --enable-linux-builtin' ebuild /usr/portage/sys-fs/zfs-kmod/zfs-kmod-0.6.2.ebuild clean configure
(cd /var/tmp/portage/sys-fs/zfs-kmod-0.6.2/work/zfs-zfs-0.6.2/ && ./copy-builtin /usr/src/linux)
mkdir -p /etc/portage/profile
echo 'sys-fs/zfs -kernel-builtin' >> /etc/portage/profile/package.use.mask
echo 'sys-fs/zfs kernel-builtin' >> /etc/portage/package.use

#finish configuring, building and installing the kernel making sure to enable dm-crypt support

#if not building zfs into the kernel, install module-rebuild
emerge module-rebuild

#install SPL and ZFS stuff zfs pulls in spl automatically
mkdir -p /etc/portage/profile
echo 'sys-fs/zfs -kernel-builtin' >> /etc/portage/profile/package.use.mask
echo 'sys-fs/zfs kernel-builtin' >> /etc/portage/package.use
emerge sys-fs/zfs

# Add zfs to the correct runlevel
rc-update add zfs boot

#initrd creation, add '--callback="module-rebuild rebuild"' to the options if not building the modules into the kernel
genkernel --luks --zfs --disklabel initramfs
