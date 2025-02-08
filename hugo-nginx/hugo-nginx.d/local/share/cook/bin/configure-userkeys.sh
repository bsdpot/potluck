#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

# check if copied-in file for jenkins key exists, and if so, copy it to authorized_keys
if [ -f /root/jenkins.pub ]; then
    echo "Adding imported /root/jenkins.pub to /root/.ssh/authorized_keys"
    cat /root/jenkins.pub >> /root/.ssh/authorized_keys
    chown -R root:wheel /root/.ssh
fi
