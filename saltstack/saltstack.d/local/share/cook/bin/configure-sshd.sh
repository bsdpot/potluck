#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

if [ -n "$SSHPORT" ]; then
    SSHPORTADJUST="$SSHPORT"
else
    SSHPORTADJUST=7777
fi

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

< "$TEMPLATEPATH/sshd_config.in" \
  sed "s${sep}%%sshport%%${sep}$SSHPORTADJUST${sep}g" | \
  sed "s${sep}%%sshuser%%${sep}$SSHUSER${sep}g" \
  > /etc/ssh/sshd_config

# generate host keys
/usr/bin/ssh-keygen -A

# setup a user
/usr/sbin/pw useradd -n "$SSHUSER" -c 'ssh user' -d "/mnt/home/$SSHUSER" -G wheel -m -s /bin/sh -h -

# configure ssh user ssh keys
mkdir -p "/mnt/home/$SSHUSER/.ssh"

# remove any existing private key
if [ -f "/mnt/home/$SSHUSER/.ssh/id_rsa" ]; then
	rm -f "/mnt/home/$SSHUSER/.ssh/id_rsa"
fi
# remove any existing public key
if [ -f "/mnt/home/$SSHUSER/.ssh/id_rsa.pub" ]; then
	rm -f "/mnt/home/$SSHUSER/.ssh/id_rsa.pub"
fi
# generate a new key
/usr/bin/ssh-keygen -q -N '' -f "/mnt/home/$SSHUSER/.ssh/id_rsa" -t rsa

# set permissions
chmod 700 "/mnt/home/$SSHUSER/.ssh"
cat "/mnt/home/$SSHUSER/.ssh/id_rsa.pub" > "/mnt/home/$SSHUSER/.ssh/authorized_keys"
chmod 700 "/mnt/home/$SSHUSER/.ssh"
chmod 600 "/mnt/home/$SSHUSER/.ssh/id_rsa"
chmod 644 "/mnt/home/$SSHUSER/.ssh/authorized_keys"
chown "$SSHUSER":wheel "/mnt/home/$SSHUSER/.ssh"

# restart ssh
service sshd enable || true
service sshd start || true
