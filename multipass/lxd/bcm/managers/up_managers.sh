
#!/bin/bash

# quit script if any erros are found
set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# Managernet is used by any docker host that joins the swarm.
echo "Creating managernet."
lxc network create managernet ipv4.address=10.0.0.1/24 ipv4.nat=false ipv6.nat=false

## Create the manager template
# Create the manager template from a snapshot that includes docker
lxc copy dockertemplate/dockerSnapshot manager-template

# push necessary files to the template including daemon.json
lxc file push ./daemon.json manager-template/etc/docker/daemon.json

# create a snapshot from which all production managers will be based.
lxc snapshot manager-template "managerTemplate"

## Start and configure the managers.
# create manager1

lxc profile create manager1
cat ./lxd_profiles/manager1.yml | lxc profile edit manager1

lxc copy manager-template/managerTemplate manager1
lxc profile apply manager1 docker,manager1

# Create an LXC storage volume of type 'dir' then mount it at /var/lib/docker in the container.
lxc storage create manager1-dockervol dir
lxc config device add manager1 dockerdisk disk source=/var/lib/lxd/storage-pools/manager1-dockervol path=/var/lib/docker 

lxc start manager1

# wait for the machine to start
# TODO find a better way to wait
sleep 5

# this kind of feels like a bind mount.
lxc exec manager1 -- mkdir -p /apps/kafka
lxc config device add manager1 code_kafka disk path=/apps/kafka source=$(pwd)/kafka


sleep 10

lxc exec manager1 -- docker swarm init --advertise-addr=10.0.0.11

wait-for-it -t 20 10.0.0.11:2377

echo "Deploying Kafka stack to manager1."
lxc exec manager1 -- docker stack deploy -c /apps/kafka/kafka.yml kafka

lxc exec manager1 -- docker stack deploy -c /apps/kafka/kafka-tools.yml kafkatools


echo "Waiting for Kafka schema-registry"
wait-for-it -t 0 10.0.0.11:8081

echo "Waiting for kafka-rest"
wait-for-it -t 0 10.0.0.11:8082 

echo "Waiting for gelf-listener to come online."
wait-for-it -t 0 10.0.0.11:12201