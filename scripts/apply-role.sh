#!/bin/bash

# Apply the device-cloud-node role. This will install the binaries (Docker, Kubernetes, Helm,...)
ansible localhost -c local -m include_role -a name=quamotion.device_cloud_node -e "preseed_docker_images=false load_kernel_modules=false ansible_distribution=Ubuntu ansible_distribution_release=bionic"
