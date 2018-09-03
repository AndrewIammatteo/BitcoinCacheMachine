#!/bin/bash

set -eu

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# call bcm_script_before.sh to perform the things that every BCM script must do prior to proceeding
bash -c $BCM_LOCAL_GIT_REPO/resources/bcm/bcm_script_before.sh

# if bcm-template lxc image exists, run the gateway template creation script.
if [[ -z $(lxc info $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME | grep BCMGatewayTemplate) ]]; then
    echo "Required snapshot 'BCMGatewayTemplate' on lxc container 'BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME' does not exist. Exiting."
    exit 1
fi

lxc copy $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME/BCMGatewayTemplate $BCM_LXC_GATEWAY_CONTAINER_NAME

# create the docker backing for 'BCM_LXC_GATEWAY_CONTAINER_NAME'
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/create_attach_lxc_storage_to_container.sh $BCM_GATEWAY_STORAGE_DOCKERVOL_CREATE $BCM_LXC_GATEWAY_CONTAINER_NAME $BCM_LXC_GATEWAY_STORAGE_DOCKERVOL_NAME"

lxc start $BCM_LXC_GATEWAY_CONTAINER_NAME

sleep 10

lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- docker swarm init --advertise-addr 127.0.0.1 >> /dev/null

# let's slap a registry mirror pull through cache.
if [[ $BCM_GATEWAY_STACKS_REGISTRYMIRROR_DEPLOY = "true" ]]; then
    bash -c "$BCM_LOCAL_GIT_REPO/docker_stacks/gateway/registry_mirror/up_lxc_registrymirror.sh $BCM_LXC_GATEWAY_CONTAINER_NAME"
    lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- wait-for-it -t 0 192.168.4.1:5000
fi

# Deploy the private registry if specified.
if [[ $BCM_GATEWAY_STACKS_PRIVATEREGISTRY_DEPLOY = "true" ]]; then
    bash -c "$BCM_LOCAL_GIT_REPO/docker_stacks/gateway/private_registry/up_lxc_private_registry.sh $BCM_LXC_GATEWAY_CONTAINER_NAME"
    lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- wait-for-it -t 0 192.168.4.1:80
fi

# now let's update gateway's dockerd daemon to use the mirror it itself is hosting.
lxc file push regmirror-daemon.json $BCM_LXC_GATEWAY_CONTAINER_NAME/etc/docker/daemon.json

lxc restart $BCM_LXC_GATEWAY_CONTAINER_NAME

sleep 15

# ### ABSOLUTE FIRST STEP 1, Let's get DHCP and DNS working.
# ## To accomplish this, we first need to build our dnsmasq docker image.
lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- docker pull farscapian/bcm-dnsmasq:latest

# disable systemd-resolved so don't have a conflict on port 53 when dnsmasq binds.
lxc file push resolved.conf $BCM_LXC_GATEWAY_CONTAINER_NAME/etc/systemd/resolved.conf
lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- chown root:root /etc/systemd/resolved.conf
lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- chmod 0644 /etc/systemd/resolved.conf

lxc restart $BCM_LXC_GATEWAY_CONTAINER_NAME

sleep 15

lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- docker run --name dnsmasq -d --restart always --net=host --cap-add=NET_ADMIN farscapian/bcm-dnsmasq:latest

# now let's update gateway's dockerd daemon to use the mirror it itself is hosting.
lxc file push finished.daemon.json $BCM_LXC_GATEWAY_CONTAINER_NAME/etc/docker/daemon.json

lxc restart $BCM_LXC_GATEWAY_CONTAINER_NAME
