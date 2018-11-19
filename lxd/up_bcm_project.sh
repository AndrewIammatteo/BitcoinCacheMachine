#!/usr/bin/env bash

set -eu
cd "$(dirname "$0")"

source ./defaults.sh

# let's make sure the cluster exists.
if [[ -z $BCM_CLUSTER_NAME ]]; then
  echo "BCM_CLUSTER_NAME not set."
  exit
fi

# let's make sure the cluster exists.
if [[ -z $BCM_PROJECT_NAME ]]; then
  echo "BCM_PROJECT_NAME not set."
  exit
fi

# let's make sure the cluster exists.
if [[ -z $BCM_CLUSTER_DIR ]]; then
  echo "BCM_CLUSTER_DIR not set."
  exit
fi


# let's make sure the cluster exists.
if [[ -z $(bcm cluster list | grep "$BCM_CLUSTER_NAME") ]]; then
  echo "Cluster '$BCM_CLUSTER_NAME' does not exist. BCM Project '$BCM_PROJECT_NAME' will not be deployed."
  exit
fi

# let's make sure the project exists.
if [[ -z $(bcm project list | grep "$BCM_PROJECT_NAME") ]]; then
  echo "Project '$BCM_PROJECT_NAME' does not exist. Can't deploy."
  exit
fi

if [[ $(lxc remote get-default) != $BCM_CLUSTER_NAME ]]; then
    if [[ ! -z $(lxc remote list | grep "$BCM_CLUSTER_NAME") ]]; then
      echo "Changing the default LXD client remote to BCM cluster '$BCM_CLUSTER_NAME'."
      lxc remote switch "$BCM_CLUSTER_NAME"
    fi
fi

# make sure we're on the right remove
if [[ -z $(lxc project list | grep "$BCM_PROJECT_NAME") ]]; then
    lxc project create $BCM_PROJECT_NAME -c features.images=false -c features.profiles=false
    lxc project switch $BCM_PROJECT_NAME
else
    echo "LXC project '$BCM_PROJECT_NAME' already exists."
fi

export BCM_LXD_OPS=$BCM_LOCAL_GIT_REPO_DIR/lxd/shared

bash -c ./bcm_core/up_lxc_core.sh
