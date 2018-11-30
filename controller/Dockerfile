FROM ubuntu:bionic
RUN apt-get update
RUN apt-get install -y apt-utils systemd lxd-client
# so scripts won't ask for interactive input.
ENV DEBIAN_FRONTEND=noninteractive

# Currently using https://github.com/romanz/trezor-agent
# https://github.com/romanz/trezor-agent/blob/master/doc/INSTALL.md
RUN apt-get install -y python3-pip python3-dev python3-tk libusb-1.0-0-dev libudev-dev
RUN apt-get install -y wait-for-it openssh-client git tor usbutils curl gnupg2

# 2. Install the TREZOR agent
RUN pip3 install Cython hidapi
RUN pip3 install trezor_agent


WORKDIR /gitrepo

# run this script to quickly configure and commit and sign a repo
RUN mkdir /bcm
ADD ./container_scripts/commit_sign_git_repo.sh /bcm/commit_sign_git_repo.sh
RUN chmod +x /bcm/commit_sign_git_repo.sh

# run this script to quickly configure and commit and sign a repo
ADD ./container_scripts/git_push.sh /bcm/git_push.sh
RUN chmod +x /bcm/git_push.sh

# run this script to quickly configure and commit and sign a repo
ADD ./container_scripts/git_pull.sh /bcm/git_pull.sh
RUN chmod +x /bcm/git_pull.sh

# run this script to quickly configure and commit and sign a repo
ADD ./container_scripts/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir -p /root/.bcm

ENV GNUPGHOME=/root/.gnupg/trezor