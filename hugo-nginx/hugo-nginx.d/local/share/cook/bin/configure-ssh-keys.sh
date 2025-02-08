#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

# create root ssh keys
mkdir -p /root/.ssh
/usr/bin/ssh-keygen -q -N '' -f /root/.ssh/id_rsa -t rsa
chown -R root:wheel /root/.ssh
chmod 700 /root/.ssh
chmod 600 /root/.ssh/id_rsa
