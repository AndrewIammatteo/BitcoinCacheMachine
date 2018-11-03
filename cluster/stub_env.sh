#!/bin/bash

set -eu
cd "$(dirname "$0")"

BCM_CLUSTER_ENDPOINT_NAME=
IS_MASTER=0
BCM_ENDPOINT_DIR=
BCM_PROVIDER_NAME=

for i in "$@"
do
case $i in
    --endpoint-name=*)
    BCM_CLUSTER_ENDPOINT_NAME="${i#*=}"
    shift # past argument=value
    ;;
    --master)
    IS_MASTER=1
    shift # past argument=value
    ;;
    --endpoint-dir=*)
    BCM_ENDPOINT_DIR="${i#*=}"
    shift # past argument=value
    ;;
    --provider=*)
    BCM_PROVIDER_NAME="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done


# create the file
mkdir -p $BCM_ENDPOINT_DIR
ENV_FILE=$BCM_ENDPOINT_DIR/.env
touch $ENV_FILE

# generate an LXD secret for the new VM lxd endpoint.
export BCM_CLUSTER_ENDPOINT_NAME=$BCM_CLUSTER_ENDPOINT_NAME
export BCM_PROVIDER_NAME=$BCM_PROVIDER_NAME
export BCM_LXD_SECRET=$(apg -n 1 -m 30 -M CN)

if [ $IS_MASTER -eq 1 ]; then
    envsubst < ./env/master_defaults.env > $ENV_FILE
elif [ $IS_MASTER -ne 1 ]; then
    envsubst < ./env/member_defaults.env > $ENV_FILE
else
    echo "Incorrect usage. Please specify whether $BCM_CLUSTER_ENDPOINT_NAME is an LXD cluster master or member."
fi

bash -c "$BCM_LOCAL_GIT_REPO/cli/commands/commit_bcm.sh 'Added files associated with stub_env.sh'"