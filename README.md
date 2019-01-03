# Quamotion Device Farm Installation Images

This repository creates scripts to create installation images (.iso files) which you can use to provision
nodes for a Quamotion Device Farm.

This images contain a copy of Ubuntu which has been preloaded with the required components - such as Docker
or Kubernetes.

## Further Reading

The scripts are based on Azure Pipelines, so you want to be familiar with that.

The scripts extract the root file system which is applied to the target machine by
[subiquity](https://github.com/CanonicalLtd/subiquity), the Ubuntu server installer.

They then launch a chroot() environment, apply the Ansible scripts and update the file system
image in the installer image.

* [How to Customize an Ubuntu Installation Disc](https://nathanpfry.com/how-to-customize-an-ubuntu-installation-disc/)
* [systemd for Administrators, Part VI- Changing Roots](http://0pointer.de/blog/projects/changing-roots)
