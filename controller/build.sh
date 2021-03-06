#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

if ! docker image list --format "{{.Repository}},{{.Tag}}" | grep -q "bcm-trezor,$BCM_VERSION"; then
    # if there's an issue resolving archive.ubuntu.com, follow these steps:
    #https://development.robinwinslow.uk/2016/06/23/fix-docker-networking-dns/#the-permanent-system-wide-fix
    
    docker build --build-arg BCM_DOCKER_BASE_TAG="$BCM_DOCKER_BASE_TAG" -t "bcm-trezor:$BCM_VERSION" .
    docker build --build-arg BCM_VERSION="$BCM_VERSION" -t "bcm-gpgagent:$BCM_VERSION" ./gpgagent/
fi
