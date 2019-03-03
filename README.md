
# <img src="./resources/images/bcmlogo_super_small.png" alt="Bitcoin Cache Machine Logo" style="float: left; margin-right: 20px;" /> Bitcoin Cache Machine

Bitcoin Cache Machine is open-source software that allows you to create a self-hosted privacy-preserving [software-defined data-center](https://en.wikipedia.org/wiki/Software-defined_data_center). BCM is built entirely with free and open-source software and is meant primarily for home and small office use in line with the spirit of decentralization.

> Note! Bitcoin Cache Machine REQUIRES a [Trezor-T](https://trezor.io/) to function! Consider buying a dedicated device for your BCM data center, or use [passphrases](https://wiki.trezor.io/Multi-passphrase_encryption_(hidden_wallets)) to maintain distinct keyspace.

## Project Status

**IMPORTANT!** BCM is brand new and unstable. It is in a proof-of-concept stage and deploys to bitcoin TESTNET mode only. Not all features are implemented. Don't put real bitcoin on it. Builds will be formally tagged once a stable proof-of-concept has been created. YOU ASSUME ALL RISK IN USING THIS SOFTWARE!!!

## Why Bitcoin Cache Machine Exists

If you're involved with Bitcoin or care about your privacy, you will undoubtedly understand the importance of [running your own fully-validating bitcoin node](https://medium.com/@lopp/securing-your-financial-sovereignty-3af6fe834603). Running a fully-validating node is easy enough--just download the software and run it on your home machine, but is that really enough to preserve your overall privacy? Did you configure it correctly? Are you also running a properly configured block explorer? Is your software up-to-date? Is your wallet software configured to consult your trusted full node? Has TOR for these services been tested properly? Are you routing your DNS queries over TOR? Are you backing up user critical data in real time?

There are many areas where your privacy can be compromised if you're not careful. BCM is meant to handle many of these concerns by creating a software-defined data center at your home or office that's pre-configured to protect your overall privacy. BCM is a distributed system, so it gets faster and more reliable as you add independent commodity hardware. If you can provide the necessary hardware (CPU, memory, disk), a LAN segment, and an internet gateway, BCM can do much of the rest. Bitcoin Cache Machine dramatically lowers the barriers to deploying and operating your own bitcoin payment infrastructure.

For more information about the motivations behind Bitcoin Cache Machine, visit the [public website](https://www.bitcoincachemachine.org/2018/11/27/introducing-bitcoin-cache-machine/).

## Development Goals

Here are some of the development goals for Bitcoin Cache Machine:

* Provide a self-contained, distributed, event-driven, software-defined data center that focuses on operational Bitcoin and Lightning-related IT infrastructure.
* Enable small-to-medium-sized scalability by adding commodity x86_x64 hardware for home and small office settings.
* Integrate free and open source software ([FOSS](https://en.wikipedia.org/wiki/Free_and_open-source_software))!
* Create a composable framework for deploying Bitcoin and Lightning-related components, databases, visualizations, web-interfaces, etc., allowing app developers to start with a fully-operational baseline data center.
* Automate the deployment and operation (e.g., backups, updates, vulnerability assessments, key and password management, etc.) of BCM deployments.
* Require hardware wallets for cryptographic operations (PGP, SSH, and Bitcoin transactions).
* Pre-configure all software to protect user's privacy (e.g., TOR for external communication, disk encryption, minimal attack surface, etc.).
* Pursue [Global Consensus and Local Consensus Models](https://twitter.com/SarahJamieLewis/status/1016832509709914112) for core platform components, e.g., Bitcoin for global financial operations and [cwtch](https://openprivacy.ca/blog/2018/06/28/announcing-cwtch/) for asynchronous, multi-peer communications.
* Enhance overall security and performance and network health by running a Tor middle relay and serving bitcoin blocks over Tor.

## How to Run Bitcoin Cache Machine

If you can run a modern Linux kernel and [LXD](https://linuxcontainers.org/lxd/), you can run BCM. BCM components run as background server-side processes only, so you'll usually want to have one or more always-on computers with a reliable Internet connection. You can run BCM in a hardware-based VM or preferably directly on bare-metal (for performance). BCM is a [distributed system](https://en.wikipedia.org/wiki/Distributed_computing), so it gets more reliable and performant as you add commodity hardware.

BCM application components are deployed using the [LXD REST](https://github.com/lxc/lxd/blob/master/doc/rest-api.md) and [Docker](https://www.docker.com/) APIs. LXD is widely available on various free and open-source linux platforms. Don't worry too much about all the dependencies. The BCM CLI installs all the software you will need.

Documentation for BCM is being migrated to [BCM Docs](https://www.bitcoincachemachine.org/docs/) website.

## Getting Started

The first step to getting started with Bitcoin Cache Machine is to clone the git repo to your new SDN controller, a user-facing desktop or laptop.

> NOTE: All BCM documentation ASSUMES you're working from a fresh install of Ubuntu (Desktop or Server) >= 18.04. Windows and MacOS are not directly supported, though you can always run Ubuntu in a VM. This goes for both the user-facing SDN controller and [dedicated back-end x86_64 data center hardware](./https://github.com/BitcoinCacheMachine/BitcoinCacheMachine/tree/master/cluster#how-to-prepare-a-physical-server-for-bcm-workloads).

Start by installing [`tor`](https://www.torproject.org/) and [`git`](https://git-scm.com/downloads) from your SDN Controller. Next, configure your local `git` client to download (clone) the BCM github repository using TOR for transport. This prevents github.com (i.e., Microsoft) from recording your real IP address. (It might also be a good idea to use a TOR browser when browsing this repo directly on github.).

```bash
sudo apt-get update
sudo apt-get install -y tor git
BCM_GITHUB_REPO_URL="https://github.com/BitcoinCacheMachine/BitcoinCacheMachine"
git config --global http.$BCM_GITHUB_REPO_URL.proxy socks5://localhost:9050
```

You can now clone the BCM repository to your machine over TOR and run setup. You can update your local BCM git repo by running `git pull` from `$BCM_GIT_DIR`.

```bash
export BCM_GIT_DIR="$HOME/git/github/bcm"
mkdir -p "$BCM_GIT_DIR"
git clone "$BCM_GITHUB_REPO_URL" "$BCM_GIT_DIR"
cd "$BCM_GIT_DIR"
./setup.sh
source ~/.bashrc
```

Feel free to change the directory in which you store the BCM repository on your machine. Just update the `BCM_GIT_DIR` variable. `setup.sh` sets up your SDN Controller so that you can use Bitcoin Cache Machine's CLI. Running `bcm` at the terminal displays top-level commands. The first place you should look for help is the CLI `--help` menus, e.g., `bcm --help`.

Consider running the BCM demo app found [`here`](./demo/up.sh) which follows the steps below in "Deploying your own BCM Infrastructure". You start by creating Trezor-backed GPG certificates and associated password store. 


You can always modify your bcm environment to control remote clusters (IP or onion). `bcm provision` deploys a base workload containing criticial components such as a SOCKS5 TOR proxy, TOR-enabled DNS, docker registries, and a comprehensive [Kafka stack](https://kafka.apache.org/). Application-level containers (WORKINGish) like [bitcoind](https://github.com/bitcoin/bitcoin), (WORK-IN-PROGRESS) [c-lightning](https://github.com/ElementsProject/lightning), (TODO) BTCPay, (TODO) web wallet interfaces, etc., are deployed using `bcm stack deploy` as discussed below.

## Deploying your own BCM Infrastructure

In general, the steps you take to deploy your own infrastructure is as follows:

1) Download BCM from github and run setup to configure your environment (done above).
2) Run `bcm init`, which initializes your management host (i.e., [SDN Controller](https://www.sdxcentral.com/sdn/definitions/sdn-controllers/)). This command downloads and installs BCM software dependencies including `docker-ce`. `bcm init` builds the relevant docker images used at the management computer including those required for Trezor integration.
3) Create a cluster by running `bcm cluster create`. A BCM cluster is defined as one or more LXD endpoints (computers) with a private networking environment that is low latency and high bandwidth, such as a home or office LAN. For this command to succeed, there MUST exist a DNS-resolvable name that is listening on SSH/TCP:22. Future versions of BCM will enable the capability to expose this SSH endpoint via an authenticated TOR onion service. When run at the SDN controller, `$BCM_GIT_DIR/setup.sh` configures your SDN controller to host `openssh-server` and its configured to listen locally at `hostname` (i.e., 127.0.1.1)). This allows you to use your SDN controller to run BCM workloads (i.e., standalone mode).
4) WORK IN PROGRESS:  Use `bcm stack deploy` to deploy supported software BCM cluster. When you deploy a component such as with `bcm stack deploy clightning --testnet`, clightning along with all its depedencies are provisioned to your active cluster (use `bcm info` and see `LXD_CLUSTER` or run `lxc remote get-default`). Essential BCM data center components that are common to ALL BCM deployments are also automatically provisioned. These services include TOR (SOCKS5 proxy, TOR-enabled DNS, & TOR Control), Docker Registry mirror and Private Registry (for docker image caching), and a Kafka logging stack which provides distributed event-driven messagaging for real-time streaming applications as well as some web interfaces that provide Kafka stack diagnostics ([topicsui](https://github.com/Landoop/kafka-topics-ui), schema-registry UI, Kafka-connect UI.

The commands above each have a reverse command, e.g., `bcm stack remove` (4), `bcm cluster destroy` (3), and `bcm reset` (2). Use `bcm info` to determine your active environment variables. `bcm show` provides an overview of your LXC containers, storage volumes, networks, images, remotes, etc..

## Planned Features

* Have BCM provide physical network underlay services: pre-configured [pi-hole](https://pi-hole.net/) to block DNS-level ad services. DHCP with name-autoregistration. A caching DNS server that uses TOR for outbound transport and consults `1.1.1.1` using a persistent TLS connection. This works ONLY when running BCM on a computer that has at LEAST TWO (2) physical network interfaces, one physically dedicated to network underlay services.
* Expose [wireguard](https://www.wireguard.com/) endpoint as ONLY ACTIVE service (per BCM project) using MACVLAN on the physical network underlay network. This helps facilitate authentication, authorization, and end-to-end encryption of clients (e.g., laptops, desktops, mobile clients) connecting to any data center services. In other words, to access privileged services hosted by your data center, you MUST FIRST VPN into the data center using a wireguard client. This piece will be implemented in a client-based docker container.
* (WORK IN PROGRESS) The BCM SDN Controller intelligently deploys components across failure domains (i.e., individual x86_64) to achieve local high-availability.
* Planned application-level software includes [clightning](https://github.com/ElementsProject/lightning), [lnd](https://github.com/lightningnetwork/lnd) & [eclair](https://github.com/ACINQ/eclair) lightning daemons, [OpenTimestamps Server](https://github.com/opentimestamps/), various wallet interfaces and/or RPC interfaces (e.g., for desktop application integration), [esplora block explorer from Blockstream](https://github.com/Blockstream/esplora), [lightning-charge](https://github.com/ElementsProject/lightning-charge), etc.. 
* Individual services (e.g., bitcoind RPC, lnd gRPC, web-based wallet interfaces, etc.) can optionally be exposed as authenticated stealth onion services allowing your TOR-enabled smartphone to securly access various interfaces from the Internet.

## How to contribute

Users wanting to contribute to the project may submit pull requests for review. A Keybase Team has been created for those wanting to discuss project ideas and coordinate. [Keybase Team for Bitcoin Cache Machine](https://keybase.io/team/btccachemachine)

You can also donate to the development of BCM by sending Bitcoin (BTC) to the following address.

* Public on-chain donations: 3KNX4GTmXETtnFWFXvFqXg9sDJCbLvD8Zf

[<img src="./resources/images/onchain_public_donation_address.png" alt="BCM Donation Address" height="250" width="250">](bitcoin:3KNX4GTmXETtnFWFXvFqXg9sDJCbLvD8Zf)