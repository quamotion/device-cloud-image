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

### Applying the quamotion_device_cloud Ansible role

First, add IP address `172.13.13.13` to the loopback adapter by configuring Netplan:

```
user@nuc:~$ cat /etc/netplan/loopback.yaml 
network:
  version: 2
  renderer: networkd
  ethernets:
    lo:
      match:
        name: lo
      addresses: [ 172.13.13.13/32 ]
```

and apply the plan:

```
netplan apply
```

Then, configure a Kubernetes cluster:

```
sudo su
ansible-galaxy install quamotion.device_cloud_node

ansible localhost -c local -m include_role -a name=quamotion.device_cloud_node -e "device_farm_role=master ansible_distribution=Ubuntu ansible_distribution_release=bionic kubernetes_apiserver_advertise_address=172.13.13.13"
```

### Deploying the quamotion-device-daemons and quamotion-device-farm Helm charts

Make sure to edit the `cloud.yaml` file

```
user@nuc:~$ cat cloud.yaml
cloud:
  project: <YOUR-PROJECT-ID>      
  apiKey: <YOUR-API-KEY>
```

Then:

```
sudo su

helm repo add quamotion http://charts.quamotion.mobi/

helm install http://charts.quamotion.mobi/quamotion-device-daemons-0.95.79-gdd1e7de7e8.tgz --name quamotion-device-daemons
helm install -f cloud.yaml http://charts.quamotion.mobi/quamotion-device-farm-0.95.79-gdd1e7de7e8.tgz --name quamotion-device-farm
```

## Further Reading

The scripts are based on Azure Pipelines, so you want to be familiar with that.

The scripts extract the root file system which is applied to the target machine by
[subiquity](https://github.com/CanonicalLtd/subiquity), the Ubuntu server installer.

They then launch a chroot() environment, apply the Ansible scripts and update the file system
image in the installer image.

* [How to Customize an Ubuntu Installation Disc](https://nathanpfry.com/how-to-customize-an-ubuntu-installation-disc/)
* [systemd for Administrators, Part VI- Changing Roots](http://0pointer.de/blog/projects/changing-roots)
