#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

# create control user
pw user add -n control -c 'Control Account' -d /mnt/matrixdata/control -G wheel -m -s /bin/sh
mkdir -p /mnt/matrixdata/control/.ssh
chown control:control /mnt/matrixdata/control/.ssh

# copy in importauthkey to enable a specific pubkey access
if [ -f /root/importauthkey ]; then
    cat /root/importauthkey > /mnt/matrixdata/control/.ssh/authorized_keys
else
    touch /mnt/matrixdata/control/.ssh/authorized_keys
fi
chown control:control /mnt/matrixdata/control/.ssh/authorized_keys
chmod u+rw /mnt/matrixdata/control/.ssh/authorized_keys
chmod go-w /mnt/matrixdata/control/.ssh/authorized_keys

# configure ssh
echo "StrictModes no" >> /etc/ssh/sshd_config
ssh-keygen -A
service sshd enable || true
service sshd start || true