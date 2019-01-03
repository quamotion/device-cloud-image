ansible localhost -c local -m include_role -a name=quamotion.device_cloud_node -e "preseed_docker_images=false"
