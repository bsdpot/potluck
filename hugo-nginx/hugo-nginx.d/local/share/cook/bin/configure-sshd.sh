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

# copy template sshd_config to host
cp -f "$TEMPLATEPATH/sshd_config.in" /etc/ssh/sshd_config

# generate host keys
/usr/bin/ssh-keygen -A || true

# enable and start sshd
service sshd enable || true
service sshd restart || true