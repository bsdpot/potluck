#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

if [ -f /root/authorized_keys_in ]; then
    echo "Adding imported keys to /root/.ssh/authorized_keys"
    cat /root/authorized_keys_in > /root/.ssh/authorized_keys
    chown -R root:wheel /root/.ssh
else
    echo "Error: no /root/authorized_keys_in file found"
    echo "#command=\"rsync --server --daemon .\",no-agent-forwarding,no-port-forwarding,no-pty,no-user-rc,no-X11-forwarding ssh-rsa key#" > /root/.ssh/authorized_keys
fi
