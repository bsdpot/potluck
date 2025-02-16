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

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
#sep=$'\001'

# make sure we have a home directory in /mnt
mkdir -p /mnt/home/

# setup a unison user
if ! id -u "unison" >/dev/null 2>&1; then
	/usr/sbin/pw useradd -n unison -c 'unison user' -d "/mnt/home/unison" -m -s /bin/sh -h -
fi

# create unison user .ssh directory
mkdir -p /mnt/home/unison/.ssh

# copy copied-in /root/importauthkey to enable specific pubkey access for unison user
# do not replace any existing file at /mnt/home/unison/.ssh/authorized_keys if exists
if [ -f /root/importauthkey ]; then
	if [ -f /mnt/home/unison/.ssh/authorized_keys ]; then
		echo "authorized_keys already exists at the destination. Skipping copy."
	else
		cp -f /root/importauthkey /mnt/home/unison/.ssh/authorized_keys
		# set permissions for .ssh directory and authorized_keys file
		chmod 700 /mnt/home/unison/.ssh
		chmod 644 /mnt/home/unison/.ssh/authorized_keys
		chown -R unison:unison /mnt/home/unison/.ssh
	fi
else
	exit_error "No /root/importauthkey file found"
fi

# create a unisondata directory and set permissions
mkdir -p /mnt/home/unison/unisondata
chown unison:unison /mnt/home/unison/unisondata
