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

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

< "$TEMPLATEPATH/sshd_config.in" \
  sed "s${sep}%%sshport%%${sep}$SSHPORTADJUST${sep}g" | \
  sed "s${sep}%%sshuser%%${sep}$SSHUSER${sep}g" \
  > /etc/ssh/sshd_config

# generate host keys
/usr/bin/ssh-keygen -A

# restart ssh
service sshd enable || true


