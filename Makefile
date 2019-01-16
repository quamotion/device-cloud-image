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

installer/etc/casper.conf: upstream/casper/filesystem.squashfs
	sudo unsquashfs -d installer/ upstream/casper/installer.squashfs
	sudo touch installer/etc/casper.conf

# Shortcut for extracing the rootfs
rootfs: squashfs-root/etc/lsb-release installer/etc/casper.conf

# Install the ansible modules, via galaxy, and fix name resolution.
# You must run this task with sudo privileges
squashfs-root/root/.ansible_galaxy: squashfs-root/etc/lsb-release
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

quamotion-device-node.iso: squashfs-root/etc/docker/daemon.json
	sudo systemd-nspawn -D squashfs-root/ /root/scripts/cleanup.sh
	sudo rm -rf squashfs-root/root/scripts/

	# Remove the resolv.conf file which was injected earlier
	sudo rm squashfs-root/etc/resolv.conf
	sudo mv squashfs-root/etc/resolv.conf.old squashfs-root/etc/resolv.conf

	# Update the (root) filesystem
	sudo touch upstream/casper/filesystem.manifest
	sudo chmod +w upstream/casper/filesystem.manifest
	sudo systemd-nspawn -D squashfs-root dpkg-query -W --showformat='${Package} ${Version}\n' | sudo tee upstream/casper/filesystem.manifest
	sudo rm upstream/casper/filesystem.squashfs
	sudo mksquashfs squashfs-root upstream/casper/filesystem.squashfs -b 1048576
	printf $(sudo du -sx --block-size=1 edit | cut -f1) | sudo tee upstream/casper/filesystem.size

	# Update the installer filesystem
	sudo rm upstream/casper/installer.squashfs
	sudo mksquashfs installer upstream/casper/installer.squashfs -b 1048576

	sudo rm -f upstream/md5sum.txt
	(cd upstream && find -type f -print0 | sudo xargs -0 md5sum | grep -v isolinux/boot.cat) | sudo tee upstream/md5sum.txt
	mkdir -p $BUILD_ARTIFACTSTAGINGDIRECTORY/iso
	xorisso -as mkisofs -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin -D -r -V "quamotion" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o quamotion-device-node.iso upstream/
#	sudo genisoimage                                                  -D -r -V "quamotion" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o quamotion-device-node.iso upstream/

iso: quamotion-device-node.iso

qemu-install:
	rm -f quamotion-device-node.img
	qemu-img create -f qcow2 quamotion-device-node.img 10G
	sudo /usr/bin/qemu-system-x86_64 -enable-kvm -cdrom quamotion-device-node.iso -boot d -m 4096 -cpu host -smp 4 -hda quamotion-device-node.img -display sdl

qemu-run:
	sudo /usr/bin/qemu-system-x86_64 -enable-kvm -m 4096 -cpu host -smp 4 -hda quamotion-device-node.img -display sdl

# Cleans everything except for the iso.
clean:
	sudo rm -rf upstream/
	sudo rm -rf squashfs-root/
	rm -f quamotion-device-node.iso
