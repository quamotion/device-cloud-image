# Quamotion Device Farm Installation Images
[![Build Status](https://dev.azure.com/qmfrederik/device-cloud-image/_apis/build/status/quamotion.device-cloud-image?branchName=master)](https://dev.azure.com/qmfrederik/device-cloud-image/_build/latest?definitionId=5?branchName=master)

This repository creates scripts to create installation images (.iso files) which you can use to provision
nodes for a Quamotion Device Farm.

This images contain a copy of Ubuntu which has been preloaded with the required components - such as Docker
or Kubernetes.

## Creating a bootable USB drive

You can use [Rufus](https://rufus.ie/) or to create a bootable USB drive based on this .iso image.

## Setting up the Device Cloud

To set up the device cloud:

1. Boot from the USB drive
2. Follow the steps in the installation wizard
3. Temporary workarounds
4. Apply the quamotion_device_cloud Ansible role
5. Deploy the quamotion-device-farm and quamotion-device-daemons Helm charts.

### Temporary workarounds

1. Edit `/etc/resolv.conf` and update the nameserver
2. Run `sudo swapoff -a`

### Applying the quamotion_device_cloud Ansible role

```
sudo su
ansible-galaxy install quamotion.device_cloud_node

ansible localhost -c local -m include_role -a name=quamotion.device_cloud_node -e "device_farm_role=master ansible_distribution=Ubuntu ansible_distribution_release=bionic"
```

### Deploying the quamotion-device-daemons and quamotion-device-farm Helm charts

Make sure to edit the `build-values.yaml` file, and then:

```
sudo su
helm install -f build-values.yml quamotion-device-daemons-0.95.76-gb56051bcfa.tgz
helm install -f build-values.yaml quamotion-device-farm-0.95.76-gb56051bcfa.tgz
```

## Further Reading

The scripts are based on Azure Pipelines, so you want to be familiar with that.

The scripts extract the root file system which is applied to the target machine by
[subiquity](https://github.com/CanonicalLtd/subiquity), the Ubuntu server installer.

They then launch a chroot() environment, apply the Ansible scripts and update the file system
image in the installer image.

* [How to Customize an Ubuntu Installation Disc](https://nathanpfry.com/how-to-customize-an-ubuntu-installation-disc/)
* [systemd for Administrators, Part VI- Changing Roots](http://0pointer.de/blog/projects/changing-roots)
