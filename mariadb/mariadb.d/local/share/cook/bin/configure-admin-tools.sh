#!/bin/sh

# shellcheck disable=SC1091
if [ -e /root/.env.cook ]; then
    . /root/.env.cook
fi

set -e
# shellcheck disable=SC3040
set -o pipefail

export PATH="/usr/local/bin:$PATH"

# make a directory for the tools
mkdir -p /root/bin

SCRIPT=$(readlink -f "$0")
TEMPLATEPATH=$(dirname "$SCRIPT")/../templates

# shellcheck disable=SC3003,SC2039
# safe(r) separator for sed
sep=$'\001'

# copy in check-master-status.sh
< "$TEMPLATEPATH/check-master-status.sh.in" \
  sed "s${sep}%%serverid%%${sep}$SERVERID${sep}g" \
  > /root/bin/check-master-status.sh

# set executable permissions
chmod +x /root/bin/check-master-status.sh

# copy in configure-mariadb-slave.sh
< "$TEMPLATEPATH/configure-mariadb-slave.sh.in" \
  sed "s${sep}%%serverid%%${sep}$SERVERID${sep}g" \
  > /root/bin/configure-mariadb-slave.sh

# set executable permissions
chmod +x /root/bin/configure-mariadb-slave.sh


