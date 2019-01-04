# This target simply downloads the iso file.
ubuntu-18.04.1.0-live-server-amd64.iso:
	curl -Lo ubuntu-18.04.1.0-live-server-amd64.iso http://releases.ubuntu.com/18.04.1.0/ubuntu-18.04.1.0-live-server-amd64.iso

# This target extracts the iso. We care mostly about the filesystem.squashfs file, so synchronize
# on that one.
upstream/casper/filesystem.squashfs: ubuntu-18.04.1.0-live-server-amd64.iso
	xorriso -osirrox on -indev ubuntu-18.04.1.0-live-server-amd64.iso  -extract / upstream/
	# Make sure the timestamp(filesystem.squashfs) > timestamp(ubuntu-18.04.1.0-live-server-adm64.iso).
	# By default this is not the case (the iso is created after the .squashfs file has been created), so
	# use touch to update the timestamp.
	touch upstream/casper/filesystem.squashfs

# This target extracts the filesystem.squashfs file. Use etc/lsb-release as an arbitary file to synchronize
# on.
squashfs-root/etc/lsb-release: upstream/casper/filesystem.squashfs
	sudo unsquashfs upstream/casper/filesystem.squashfs
	# Make sure the timestamp(lsb-release) > timestamp(filesystem.squashfs).
	# By default this is not the case (the squashfs is created after the lsb-release file has been created), so
	# use touch to update the timestamp.
	sudo touch squashfs-root/etc/lsb-release

# Shortcut for extracing the rootfs
rootfs: squashfs-root/etc/lsb-release

# Install the ansible modules, via galaxy, and fix name resolution
squashfs-root/root/.ansible_galaxy: squashfs-root/etc/lsb-release
	stat squashfs-root/root/.ansible_galaxy || (echo "Please run this command as root" && exit 1)

	# https://github.com/systemd/systemd/pull/9024 contains changes to bind mount resolv-conf
	# into the chroot. Available in systemd 239 and above, so that means Ubuntu 18.10 and later.
	sudo mv squashfs-root/etc/resolv.conf squashfs-root/etc/resolv.conf.old
	sudo cp -L /etc/resolv.conf squashfs-root/etc/resolv.conf

	# Copy the scripts inside the RootFS, and execute them
	sudo cp -r scripts/ squashfs-root/root/scripts/
	sudo systemd-nspawn -D squashfs-root/ /root/scripts/prepare-ansible.sh

prepare: squashfs-root/root/.ansible_galaxy

squashfs-root/etc/docker/daemon.json: squashfs-root/root/.ansible_galaxy
	sudo systemd-nspawn -D squashfs-root/ /root/scripts/apply-role.sh

apply-role: squashfs-root/etc/docker/daemon.json

# Cleans everything except for the iso.
clean:
	sudo rm -rf upstream/
	sudo rm -rf squashfs-root/
