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

# temp removing, not used for galera clustering
## copy in check-master-status.sh
#< "$TEMPLATEPATH/check-master-status.sh.in" \
#  sed "s${sep}%%serverid%%${sep}$SERVERID${sep}g" \
#  > /root/bin/check-master-status.sh
#
## set executable permissions
#chmod +x /root/bin/check-master-status.sh

# copy in check-galera-status.sh
< "$TEMPLATEPATH/check-galera-status.sh.in" \
  sed "s${sep}%%serverid%%${sep}$SERVERID${sep}g" \
  > /root/bin/check-galera-status.sh

# set executable permissions
chmod +x /root/bin/check-galera-status.sh

# copy in check-galera-cluster-size.sh
< "$TEMPLATEPATH/check-galera-cluster-size.sh.in" \
  sed "s${sep}%%serverid%%${sep}$SERVERID${sep}g" \
  > /root/bin/check-galera-cluster-size.sh

# set executable permissions
chmod +x /root/bin/check-galera-cluster-size.sh


