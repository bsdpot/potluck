#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

# if sshd_config has been copied in correctly
# replace /etc/ssh/sshd_config
if [ -f /root/sshd_config_in ]; then
    echo "Setting up ssh server"
    cp -f /root/sshd_config_in /etc/ssh/sshd_config
    echo "Manually setting up host keys"
    cd /etc/ssh
    /usr/bin/ssh-keygen -A
	# restarting instead of starting
    echo "Starting sshd"
    service sshd restart || true
else
    echo "There is no /root/sshd_config_in file"
fi
