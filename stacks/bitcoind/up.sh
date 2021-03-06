#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

bcm stack start tor

source ./env.sh

# env.sh has some of our naming conventions for DOCKERVOL and HOSTNAMEs and such.
source "$BCM_GIT_DIR/project/shared/env.sh"

# prepare the image.
"$BCM_GIT_DIR/project/shared/docker_image_ops.sh" \
--build-context="$(pwd)/build/" \
--container-name="$LXC_HOSTNAME" \
--image-name="$IMAGE_NAME"

# push the stack and build files
lxc file push -p -r "$BCM_STACKS_DIR/bitcoind/stack" "$BCM_GATEWAY_HOST_NAME/root/stacks/$TIER_NAME/$STACK_NAME"

# get bitcoind ENV vars. This file is also
source ./env.sh --chain="$BCM_ACTIVE_CHAIN"

# these are mainnet defaults. We upload blocks on mainnet and testnet.
# by default each mainnet node of operation will do full block validation
# but will SKIP script verification up to the assumevalid block. For testnet
# nodes, the chainstate will automitically be uploaded if it exists.
UPLOAD_BLOCKS=1
UPLOAD_CHAINSTATE=0

SRC_DIR="$HOME/.bitcoin"
DEST_DIR="/var/lib/docker/volumes/bitcoind-$BCM_ACTIVE_CHAIN""_data/_data"
if [[ $BCM_ACTIVE_CHAIN == "testnet" ]]; then
    SRC_DIR="$HOME/.bitcoin/testnet3"
    DEST_DIR="$DEST_DIR/testnet3"
    UPLOAD_CHAINSTATE=1
    elif [[ $BCM_ACTIVE_CHAIN == 'regtest' ]]; then
    SRC_DIR="$HOME/.bitcoin/regtest"
    DEST_DIR="$DEST_DIR/regtest"
    UPLOAD_BLOCKS=0
fi

BLOCKS_DIR="$DEST_DIR/blocks"

# let's make sure docker has the 'data' volume defined so we can do restore or preseed block/chainstate data
NEW_INSTALL=0
if ! lxc exec "$LXC_HOSTNAME" -- docker volume list | grep -q "$DOCKER_VOLUME_NAME"; then
    lxc exec "$LXC_HOSTNAME" -- docker volume create "$DOCKER_VOLUME_NAME"
    
    # if we just now created the docker volume in this script run, then we need
    # to indicate downstream that preseeding should take place. If the volume
    # already exists we assume preseeding has already taken place. The node should
    # proceed from wherever it left off.
    NEW_INSTALL=1
fi

# these are extremely useful time-saving procedures when developing BCM
# if the $HOME/.bitcoin/blocks (or testnet3/blocks) directory exists,
# then we can use it to seed # our new full node with blocks.
# this is better because we won't have to bog the TOR network down.
if [[ ! -d "$SRC_DIR/blocks" ]]; then
    # TODO, see if we can minimize the amount of blocks to be uploaded, eg., last 300 blocks.
    UPLOAD_BLOCKS=0
fi

if [[ ! -d "$SRC_DIR/chainstate" ]]; then
    UPLOAD_CHAINSTATE=0
fi

# if an existing bcm backup exists, then we will restore THAT first. This helps
# avoid IDB using your Internet connection. If there's no backup, we can try uploading blocks
# manually if they're in ~/.bitcoin. If all else fails, we will do IDB over Internet.
BACKUP_DIR="$BCM_WORKING_DIR/$CLUSTER_NAME/backups/$STACK_NAME"
INITIAL_BLOCK_DOWNLOAD=1
if [[ -d $BACKUP_DIR ]]; then
    if ! lxc exec "$LXC_HOSTNAME" -- docker volume list | grep -q "bitcoind-$BCM_ACTIVE_CHAIN""-data"; then
        bcm restore bitcoind
    fi
else
    if [[ $NEW_INSTALL == 1 ]]; then
        # we can look on disk for a .bitcoin directory; if it exists, we can push that
        # BCM-based backups are more precise and tested.
        if [[ "$UPLOAD_BLOCKS" == 1 ]]; then
            lxc file push -r -p "$SRC_DIR/blocks" "$LXC_HOSTNAME/$DEST_DIR"
        fi
        
        if [[ "$UPLOAD_CHAINSTATE" == 1 ]]; then
            lxc file push -r -p "$SRC_DIR/chainstate" "$LXC_HOSTNAME/$DEST_DIR"
            INITIAL_BLOCK_DOWNLOAD=0
        fi
    fi
fi

lxc exec "$BCM_GATEWAY_HOST_NAME" -- env DOCKER_IMAGE="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$BCM_VERSION" \
BCM_ACTIVE_CHAIN="$BCM_ACTIVE_CHAIN" \
LXC_HOSTNAME="$LXC_HOSTNAME" \
INITIAL_BLOCK_DOWNLOAD="$INITIAL_BLOCK_DOWNLOAD" \
BITCOIND_RPC_PORT="$BITCOIND_RPC_PORT" \
docker stack deploy -c "/root/stacks/$TIER_NAME/$STACK_NAME/stack/$STACK_NAME.yml" "$STACK_NAME-$BCM_ACTIVE_CHAIN"
