#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

#SCRIPT=$(readlink -f "$0")
#TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# add git user
pw user add -n git -c 'Git Server' -d /var/db/git -G wheel -m -s /bin/sh

mkdir -p /var/db/git/.ssh
chown git:git /var/db/git/.ssh
touch /var/db/git/.ssh/authorized_keys
# if we have a copied-in publickey, add to authorized_keys
# overwrite the file, else nomad job restarts will make
# a large file
if [ -f /root/publickey ]; then
	cat /root/publickey > /var/db/git/.ssh/authorized_keys
fi
# make sure to set permissions
chown git:git /var/db/git/.ssh/authorized_keys
chmod u+rw /var/db/git/.ssh/authorized_keys
chmod go-w /var/db/git/.ssh/authorized_keys

# adjust ssh settings
echo "StrictModes no" >> /etc/ssh/sshd_config

# generate host keys
/usr/bin/ssh-keygen -A

# enable ssh service
service sshd enable || true

