#!/bin/bash

set -Eeuo pipefail

source /bcm/proxy_ip_determinant.sh

if [[ -z "$TOR_PROXY" ]]; then
    echo "ERROR:  TOR_PROXY could not be determined."
    exit
fi
wait-for-it -t 10 "$TOR_PROXY"

if [[ -z "$TOR_CONTROL" ]]; then
    echo "ERROR:  TOR_CONTROL could not be determined."
    exit
fi
wait-for-it -t 10 "$TOR_CONTROL"

# wait for the managementt plane
bash -c "/bcm/wait_for_gogo.sh --gogofile=$STACK_GOGO_FILE"


touch /root/.bitcoin/bitcoind-rtl.conf
echo "restlisten=$OVERLAY_NETWORK_IP:$BITCOIND_RPC_PORT" > /root/.bitcoin/bitcoind-rtl.conf
if [[ $BCM_ACTIVE_CHAIN == "testnet" ]]; then
    echo "testnet=1" >> /root/.bitcoin/bitcoind-rtl.conf
    elif [[ $BCM_ACTIVE_CHAIN == "regtest" ]]; then
    echo "regtest=1" >> /root/.bitcoin/bitcoind-rtl.conf
fi

# run bitcoind
bitcoind -conf=/root/.bitcoin/bitcoin.conf \
-datadir=/root/.bitcoin \
-proxy="$TOR_PROXY" \
-torcontrol="$TOR_CONTROL" \
-zmqpubrawblock="tcp://$OVERLAY_NETWORK_IP:$BITCOIND_ZMQ_BLOCK_PORT" \
-zmqpubrawtx="tcp://$OVERLAY_NETWORK_IP:$BITCOIND_ZMQ_TX_PORT" \
-rpcbind="$OVERLAY_NETWORK_IP:$BITCOIND_RPC_PORT" \
-debug=tor "$BITCOIND_CHAIN_TEXT"
